# AGI System Usage Guide

> **Important**: The commands below target features that have not been fully implemented. Expect only initialization and shutdown behavior when running the current code.

## Basic Usage

### Running the System
```bash
./build/agi_system [options]
```

### Common Options
- `--config <file>`: Specify configuration file
- `--debug`: Enable debug mode
- `--verbose`: Enable verbose output
- `--memory <size>`: Set memory size (in MB)
- `--mode <mode>`: Set operation mode

## Operation Modes

### Training Mode
```bash
./build/agi_system --mode train --config training_config.json
```
- Trains the neural network
- Updates decision policies
- Optimizes memory usage

### Inference Mode
```bash
./build/agi_system --mode inference --config inference_config.json
```
- Performs predictions
- Makes decisions
- Processes input/output

### Debug Mode
```bash
./build/agi_system --mode debug --config debug_config.json
```
- Enables detailed logging
- Shows memory usage
- Displays performance metrics

## Configuration

### Memory Configuration
```json
{
  "working_memory_size": 1024,
  "long_term_memory_size": 102400,
  "block_size": 4096,
  "priority_levels": 3
}
```

### Neural Network Configuration
```json
{
  "layers": [784, 128, 64, 10],
  "learning_rate": 0.001,
  "batch_size": 32,
  "optimizer": "adam"
}
```

### Decision Engine Configuration
```json
{
  "exploration_rate": 0.1,
  "discount_factor": 0.99,
  "replay_buffer_size": 10000,
  "update_frequency": 1000
}
```

## Performance Monitoring

### Memory Usage
```bash
./build/agi_system --monitor memory
```
- Shows memory allocation
- Displays fragmentation
- Reports garbage collection

### Performance Metrics
```bash
./build/agi_system --monitor performance
```
- CPU usage
- Memory throughput
- I/O operations
- Decision latency

## Error Handling

### Common Errors
- Memory allocation failure
- Invalid configuration
- I/O errors
- Neural network errors

### Debugging
```bash
./build/agi_system --debug --log-level debug
```
- Detailed error messages
- Stack traces
- Memory dumps
- Performance profiles

## Docker Usage

Build the container image and run the system in an isolated environment.

```bash
docker build -t agi-system ..
docker run --rm agi-system
```

Alternatively use Docker Compose:

```bash
docker-compose up
```

## Support

For more examples and troubleshooting tips, see the README or open an issue on GitHub.

## Project Status

This guide describes intended functionality. The current implementation is a
minimal demonstration that initializes and shuts down without performing real
AGI tasks.

## Python Utilities

The `python/` directory provides experimental scripts that use PyTorch and
Gymnasium for rapid prototyping. Run `python/ppo_agent.py` to try the PPO
trainer on CartPole.

