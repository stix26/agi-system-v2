#!/bin/bash

# Run the AGI system with the example configuration
"$(dirname "$0")/../build/agi_system" config/example_system_config.cfg examples/example_input.txt examples/example_output.txt

