#!/bin/bash

# Run the built AGI system from the repository root
DIR="$(dirname "$0")/.."
"$DIR"/build/agi_system "$@"

