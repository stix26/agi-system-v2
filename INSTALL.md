# AGI System Installation Guide

> **Disclaimer**: This installation process targets an incomplete prototype. Expect placeholder behavior when running the resulting binaries.

## Prerequisites
- NASM (Netwide Assembler) 2.15.05 or later
- GNU Make 4.3 or later
- GNU Linker (ld) 2.38 or later
- GDB (for debugging) 12.1 or later
- Python 3.8+ (for build scripts)

## Installation Steps

### Step 1: Clone the Repository
```bash
git clone https://github.com/stix26/agi-system.git
cd agi-system
```

### Step 2: Install Dependencies

#### On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install nasm make binutils gdb python3 python3-pip
```

#### On macOS:
```bash
brew install nasm make binutils gdb python3
```
The Makefile detects macOS automatically and assembles with Mach-O output. Ensure the Xcode command line tools are installed to provide the `ld` and `clang` linker utilities.

### Step 3: Build the System
```bash
make clean
make all
```

### Step 4: Run Tests
```bash
make test
```

### Step 5: Install System (Optional)
```bash
sudo make install
```

## Verification

To verify the installation:
```bash
./build/agi_system --version
```

## Troubleshooting

If you encounter build errors:
1. Ensure all dependencies are installed
2. Check NASM version: `nasm --version`
3. Verify Make version: `make --version`
4. Check system architecture: `uname -m`

For additional help, please open an issue on GitHub.
