# AGI System Makefile

# Compiler and flags
ASM = nasm
ASMFLAGS = -f elf64
LDFLAGS = -no-pie

# Directories
SRC_DIR = src
BUILD_DIR = build
CORE_DIR = $(SRC_DIR)/core
UTILS_DIR = $(SRC_DIR)
LIB_DIR = $(SRC_DIR)/lib

# Source files
CORE_SRCS = $(wildcard $(CORE_DIR)/*.asm)
UTILS_SRCS =
LIB_SRCS = $(wildcard $(LIB_DIR)/*.asm)
MAIN_SRC = $(SRC_DIR)/main.asm

# Object files
CORE_OBJS = $(CORE_SRCS:$(CORE_DIR)/%.asm=$(BUILD_DIR)/%.o)
UTILS_OBJS = $(UTILS_SRCS:$(UTILS_DIR)/%.asm=$(BUILD_DIR)/%.o)
LIB_OBJS = $(LIB_SRCS:$(LIB_DIR)/%.asm=$(BUILD_DIR)/%.o)
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

# Compile utility components
$(BUILD_DIR)/%.o: $(UTILS_DIR)/%.asm | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) $< -o $@

# Compile library components
$(BUILD_DIR)/%.o: $(LIB_DIR)/%.asm | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) $< -o $@

# Compile main program
$(MAIN_OBJ): $(MAIN_SRC) | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) $< -o $@

# Link everything together
$(TARGET): $(MAIN_OBJ) $(CORE_OBJS) $(UTILS_OBJS) $(LIB_OBJS)
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
	install -m 755 $(TARGET) /usr/local/bin/

# Uninstall system
uninstall:
	rm -f /usr/local/bin/$(TARGET)

.PHONY: all clean run debug install uninstall
