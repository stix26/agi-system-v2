#!/bin/bash

# Convenience build script. It simply invokes make so that
# users unfamiliar with the toolchain can run `tools/build.sh`.

set -e
make -C .. clean
make -C .. all

echo "Build complete. Run ../build/agi_system to execute."

