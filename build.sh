#!/bin/bash

# Create build directory if it doesn't exist
mkdir -p build

# Assemble all .asm files
nasm -f macho64 src/main.asm -o build/main.o
nasm -f macho64 src/core/attention.asm -o build/attention.o
nasm -f macho64 src/core/memory.asm -o build/memory.o
nasm -f macho64 src/core/decision.asm -o build/decision.o
nasm -f macho64 src/core/io.asm -o build/io.o
nasm -f macho64 src/utils.asm -o build/utils.o

# Link all object files
ld -o build/agi_system \
   build/main.o \
   build/attention.o \
   build/memory.o \
   build/decision.o \
   build/io.o \
   build/utils.o \
   -lSystem \
   -syslibroot `xcrun -sdk macosx --show-sdk-path` \
   -e _start \
   -arch arm64

# Make executable
chmod +x build/agi_system

echo "Build complete. Executable created at build/agi_system" 
