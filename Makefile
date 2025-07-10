# AGI System Makefile - Optimized Version

# Compiler and flags
ASM = nasm
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Build configuration
BUILD_TYPE ?= release
JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Platform-specific settings
ifeq ($(UNAME_S),Darwin)
    ASMFLAGS = -f macho64
    LDFLAGS = -macosx_version_min 10.13 -lSystem
    STRIP_FLAGS = -x
else
    ASMFLAGS = -f elf64
    LDFLAGS = -no-pie
    STRIP_FLAGS = --strip-unneeded
endif

# Architecture-specific optimizations
ifeq ($(UNAME_M),x86_64)
    ASMFLAGS += -DCPU_X86_64=1
else ifeq ($(UNAME_M),aarch64)
    ASMFLAGS += -DCPU_ARM64=1
endif

# Build type configurations
ifeq ($(BUILD_TYPE),debug)
    ASMFLAGS += -g -F dwarf
    LDFLAGS += -g
else ifeq ($(BUILD_TYPE),release)
    ASMFLAGS += -O3
    LDFLAGS += -O3 -s
    STRIP_BINARY = yes
else ifeq ($(BUILD_TYPE),profile)
    ASMFLAGS += -g -O2
    LDFLAGS += -g -O2 -pg
endif

# Enable parallel builds
MAKEFLAGS += -j$(JOBS)

# Directories
SRC_DIR = src
BUILD_DIR = build
CORE_DIR = $(SRC_DIR)/core
BENCH_DIR = benchmarks

# Source files
CORE_SRCS = $(wildcard $(CORE_DIR)/*.asm)
MAIN_SRC = $(SRC_DIR)/main.asm

# Object files
CORE_OBJS = $(CORE_SRCS:$(CORE_DIR)/%.asm=$(BUILD_DIR)/%.o)
MAIN_OBJ = $(BUILD_DIR)/main.o
ALL_OBJS = $(MAIN_OBJ) $(CORE_OBJS)

# Target executable
TARGET = $(BUILD_DIR)/agi_system

# Performance monitoring
PERF_LOG = $(BUILD_DIR)/performance.log
BENCHMARK_TARGET = $(BUILD_DIR)/benchmark

# Default target
all: $(TARGET)

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@echo "Build directory created: $(BUILD_DIR)"

# Compile core components with dependency tracking
$(BUILD_DIR)/%.o: $(CORE_DIR)/%.asm | $(BUILD_DIR)
	@echo "Compiling core component: $<"
	$(ASM) $(ASMFLAGS) $< -o $@
	@echo "$@: $<" > $@.d

# Compile main program
$(MAIN_OBJ): $(MAIN_SRC) | $(BUILD_DIR)
	@echo "Compiling main program: $<"
	$(ASM) $(ASMFLAGS) $< -o $@
	@echo "$@: $<" > $@.d

# Link everything together with timing
$(TARGET): $(ALL_OBJS)
	@echo "Linking executable..."
	@start_time=$$(date +%s.%N); \
	ld $(ALL_OBJS) -o $@ $(LDFLAGS); \
	end_time=$$(date +%s.%N); \
	link_time=$$(echo "$$end_time - $$start_time" | bc -l 2>/dev/null || echo "N/A"); \
	echo "Link time: $$link_time seconds" | tee -a $(PERF_LOG)
ifeq ($(STRIP_BINARY),yes)
	@echo "Stripping binary for release..."
	strip $(STRIP_FLAGS) $@
endif
	@echo "Build complete: $@"
	@ls -lh $@

# Build with timing information
timed-build: clean
	@echo "Starting timed build..."
	@start_time=$$(date +%s.%N); \
	$(MAKE) all BUILD_TYPE=$(BUILD_TYPE) -j$(JOBS); \
	end_time=$$(date +%s.%N); \
	total_time=$$(echo "$$end_time - $$start_time" | bc -l 2>/dev/null || echo "N/A"); \
	echo "Total build time: $$total_time seconds" | tee -a $(PERF_LOG)

# Build different configurations
debug: 
	$(MAKE) all BUILD_TYPE=debug

release:
	$(MAKE) all BUILD_TYPE=release

profile:
	$(MAKE) all BUILD_TYPE=profile

# Performance benchmarking
benchmark: $(TARGET)
	@echo "Running performance benchmarks..."
	@mkdir -p $(BENCH_DIR)
	time ./$(TARGET) 2>&1 | tee $(BENCH_DIR)/runtime_benchmark.log
	@if command -v perf >/dev/null 2>&1; then \
		echo "Running perf analysis..."; \
		perf stat -e cycles,instructions,cache-misses,branch-misses ./$(TARGET) 2>&1 | tee $(BENCH_DIR)/perf_analysis.log; \
	fi

# Size optimization analysis
size-analysis: $(TARGET)
	@echo "Binary size analysis:"
	@size $(TARGET) | tee $(BUILD_DIR)/size_analysis.log
	@if command -v objdump >/dev/null 2>&1; then \
		echo "Section analysis:"; \
		objdump -h $(TARGET) | tee -a $(BUILD_DIR)/size_analysis.log; \
	fi

# Clean build files with timing
clean:
	@echo "Cleaning build directory..."
	@start_time=$$(date +%s.%N); \
	rm -rf $(BUILD_DIR) $(BENCH_DIR); \
	end_time=$$(date +%s.%N); \
	clean_time=$$(echo "$$end_time - $$start_time" | bc -l 2>/dev/null || echo "N/A"); \
	echo "Clean time: $$clean_time seconds"

# Force rebuild
rebuild: clean all

# Run the system with performance monitoring
run: $(TARGET)
	@echo "Running AGI system..."
	@if command -v time >/dev/null 2>&1; then \
		echo "Performance monitoring enabled"; \
		time -v ./$(TARGET) 2>&1 | tee $(BUILD_DIR)/runtime_stats.log; \
	else \
		./$(TARGET); \
	fi

# Debug the system
debug-run: debug
	@echo "Starting GDB session..."
	gdb $(TARGET)

# Profile the system
profile-run: profile
	@echo "Running with profiling..."
	./$(TARGET)
	@if [ -f gmon.out ]; then \
		gprof $(TARGET) gmon.out > $(BUILD_DIR)/profile_analysis.log; \
		echo "Profile analysis saved to $(BUILD_DIR)/profile_analysis.log"; \
	fi

# Memory analysis (if valgrind is available)
memory-check: debug
	@if command -v valgrind >/dev/null 2>&1; then \
		echo "Running memory analysis with Valgrind..."; \
		valgrind --tool=memcheck --leak-check=full --track-origins=yes ./$(TARGET) 2>&1 | tee $(BUILD_DIR)/memory_analysis.log; \
	else \
		echo "Valgrind not available for memory analysis"; \
	fi

# Install system
install: release
	@echo "Installing AGI system..."
	install -m 755 $(TARGET) /usr/local/bin/agi_system
	@echo "Installation complete"

# Uninstall system
uninstall:
	@echo "Uninstalling AGI system..."
	rm -f /usr/local/bin/agi_system
	@echo "Uninstall complete"

# Show build information
info:
	@echo "Build Information:"
	@echo "  Platform: $(UNAME_S) $(UNAME_M)"
	@echo "  Build Type: $(BUILD_TYPE)"
	@echo "  Parallel Jobs: $(JOBS)"
	@echo "  ASM Flags: $(ASMFLAGS)"
	@echo "  LD Flags: $(LDFLAGS)"
	@echo "  Source Files: $(words $(CORE_SRCS)) core + 1 main"

# Include dependency files
-include $(ALL_OBJS:.o=.d)

# Phony targets
.PHONY: all clean run debug-run profile-run rebuild timed-build debug release profile benchmark size-analysis memory-check install uninstall info

# Performance targets
.PHONY: performance-all
performance-all: timed-build benchmark size-analysis

# Print help information
help:
	@echo "AGI System Build Targets:"
	@echo "  all          - Build the system (default)"
	@echo "  debug        - Build debug version"
	@echo "  release      - Build optimized release version"
	@echo "  profile      - Build with profiling enabled"
	@echo "  timed-build  - Build with timing information"
	@echo "  benchmark    - Run performance benchmarks"
	@echo "  size-analysis- Analyze binary size"
	@echo "  memory-check - Run memory analysis (requires valgrind)"
	@echo "  clean        - Remove build files"
	@echo "  rebuild      - Clean and build"
	@echo "  run          - Run the system"
	@echo "  debug-run    - Run with debugger"
	@echo "  profile-run  - Run with profiling"
	@echo "  install      - Install system globally"
	@echo "  uninstall    - Remove installed system"
	@echo "  info         - Show build configuration"
	@echo "  help         - Show this help message"
