#!/bin/bash

# Simple build script for Linux environments
# This script wraps the Makefile so that users can run
# `./build.sh` as a convenient shortcut.

set -e

make clean
make all

echo "Build complete. Executable created at build/agi_system"
