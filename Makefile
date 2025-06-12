# AGI System Makefile

# Compiler and flags
ASM = nasm
UNAME_S := $(shell uname -s)
ASMFLAGS = -f elf64
LDFLAGS = -no-pie
ifeq ($(UNAME_S),Darwin)
    ASMFLAGS = -f macho64
    LDFLAGS = -macosx_version_min 10.13 -lSystem
endif

# Directories
SRC_DIR = src
BUILD_DIR = build
CORE_DIR = $(SRC_DIR)/core

# Source files
CORE_SRCS = $(wildcard $(CORE_DIR)/*.asm)
MAIN_SRC = $(SRC_DIR)/main.asm

# Object files
CORE_OBJS = $(CORE_SRCS:$(CORE_DIR)/%.asm=$(BUILD_DIR)/%.o)
MAIN_OBJ = $(BUILD_DIR)/main.o

# Target executable
TARGET = $(BUILD_DIR)/agi_system

# Default target
all: $(TARGET)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile core components
$(BUILD_DIR)/%.o: $(CORE_DIR)/%.asm | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) $< -o $@


# Compile main program
$(MAIN_OBJ): $(MAIN_SRC) | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) $< -o $@

# Link everything together
$(TARGET): $(MAIN_OBJ) $(CORE_OBJS)
	ld $^ -o $@ $(LDFLAGS)

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

# Run the system
run: $(TARGET)
	./$(TARGET)

# Debug the system
debug: $(TARGET)
	gdb $(TARGET)

# Install system
install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/agi_system

# Uninstall system
uninstall:
	rm -f /usr/local/bin/agi_system

.PHONY: all clean run debug install uninstall
