#!/bin/bash
# Setup script for AGI System
# Installs required system packages and Python dependencies
set -e

# Ensure script is run from repository root
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

# Install system packages if missing
need_pkg_install=false

if ! command -v nasm >/dev/null 2>&1; then
    need_pkg_install=true
    echo "NASM not found. It will be installed."
fi
if ! command -v make >/dev/null 2>&1; then
    need_pkg_install=true
    echo "make not found. Build tools will be installed."
fi
if ! command -v ld >/dev/null 2>&1; then
    need_pkg_install=true
    echo "ld not found. Binutils will be installed."
fi
if [ "$need_pkg_install" = true ]; then
    sudo apt-get update
    sudo apt-get install -y build-essential nasm
fi

# Ensure Python and pip
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3 not found. Installing Python3 and pip."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip
fi

# Install Python dependencies
if [ -f requirements.txt ]; then
    echo "Installing Python dependencies..."
    pip3 install --user -r requirements.txt
fi

echo "Setup complete."
