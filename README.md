# Advanced AGI System

A sophisticated artificial general intelligence system implemented in x86-64 assembly language. The system features advanced neural networks, memory management, decision making, and I/O handling capabilities.

> **Note**: This repository is experimental and many modules are only placeholders. The code demonstrates initialization and shutdown logic but does **not** provide a complete AGI implementation.

## Architecture

The system consists of several key components:

### Core Components

#### Memory Management (`memory_manager.asm`)
- Hierarchical memory structure (working and long-term)
- Memory block management with priority levels
- Garbage collection and defragmentation
- Memory consolidation and cleanup

#### Neural Network (`neural_network.asm`)
- Multi-layer neural network implementation
- Backpropagation and gradient descent
- Activation functions and loss calculations
- Weight optimization

#### Decision Engine (`decision.asm`)
- Reinforcement learning capabilities
- Policy and value networks
- Experience replay buffer
- Planning and simulation

#### I/O Handler (`io_handler.asm`)
- Multi-modal input/output support
- Stream-based processing
- Efficient buffer management
- Modality-specific handlers

### Supporting Components

#### Math Utilities
- Matrix operations
- Vector calculations
- Statistical functions
- Optimization algorithms

#### Memory Operations
- Memory block operations
- Data structure management
- Memory alignment
- Cache optimization

#### Utilities (`utils.asm`)
- System utilities
- Helper functions
- Debugging tools
- Performance monitoring

## Building

### Prerequisites
- NASM 2.15.05 or later
- GNU Make 4.3 or later
- GNU Linker (ld) 2.38 or later
- GDB 12.1 or later (for debugging)
- Python 3.8+ (for build scripts)

### Build Steps
1. Clone the repository:
```bash
git clone https://github.com/stix26/agi-system.git
cd agi-system
```

2. Build the system:
```bash
make clean
make all
```

On macOS, the Makefile automatically switches to Mach-O output when `uname` reports `Darwin`. Ensure Xcode command line tools are installed so that `ld` and `clang` are available.

3. Run the system:
```bash
make run
```

4. Debug the system:
```bash
make debug
```

## Installation

To install the system globally:
```bash
sudo make install
```

To uninstall:
```bash
sudo make uninstall
```

## Usage

The system can be used in several ways:

1. Standalone mode:
```bash
./build/agi_system
```

2. Debug mode:
```bash
make debug
```

3. With custom configuration:
```bash
./build/agi_system --config config.json
```

## Docker

The repository provides a `Dockerfile` and a `docker-compose.yml` for
containerized builds. Using Docker ensures the correct toolchain is
available and isolates the AGI system from the host environment.

### Build the image
```bash
docker build -t agi-system .
```

### Run the container
```bash
docker run --rm agi-system
```

Or start the service with Docker Compose:
```bash
docker-compose up
```

## Python Integration

Advanced training utilities are provided in the `python/` directory. These
scripts leverage modern machine learning frameworks to experiment with
reinforcement learning and transformer models outside of the core assembly
runtime.

### Example: PPO Agent
```bash
pip install -r requirements.txt
python python/ppo_agent.py
```
This launches a small PPO trainer for the CartPole environment and prints the
episode rewards.

## Configuration

The system can be configured through various parameters:

- Memory parameters:
  - Working memory size
  - Long-term memory size
  - Block size
  - Priority levels

- Neural network parameters:
  - Layer sizes
  - Learning rates
  - Activation functions
  - Optimization settings

- Decision parameters:
  - Exploration rate
  - Discount factor
  - Batch size
  - Update frequency

- I/O parameters:
  - Buffer sizes
  - Timeouts
  - Stream configurations
  - Error handling

## Development

### Adding New Features

1. Create new assembly file in `src/core/` directory
2. Add dependencies in Makefile
3. Implement functionality
4. Update main program to integrate new feature

### Debugging

1. Use GDB for debugging:
```bash
make debug
```

2. Set breakpoints:
```bash
(gdb) break main
(gdb) run
```

3. Inspect memory:
```bash
(gdb) x/10x $rsp
```

## Performance

The system is optimized for:
- Low latency processing
- Efficient memory usage
- Parallel computation
- Real-time response

## Project Status

This repository is a proof of concept. Many components are placeholders or
stubs intended for experimentation. The current assembly implementation only
demonstrates initialization and shutdown sequences. Advanced features described
in the documentation are not fully implemented. **Do not rely on this code for
production use.**

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Thanks to all contributors
- Inspired by various AGI research
- Built with modern assembly techniques

## Contact

For questions and support, please open an issue on GitHub.
