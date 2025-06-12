#!/bin/bash
nasm -f elf64 -o main.o src/main.asm
nasm -f elf64 -o neural_network.o src/neural_network.asm
nasm -f elf64 -o memory_manager.o src/memory_manager.asm
nasm -f elf64 -o io_handler.o src/io_handler.asm
nasm -f elf64 -o decision_engine.o src/decision_engine.asm

ld -o agi_system main.o neural_network.o memory_manager.o io_handler.o decision_engine.o -m elf_x86_64
echo "Build complete. Run ./agi_system to execute."