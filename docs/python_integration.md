# Python Integration

The `python/` directory contains experimental machine learning utilities written
in Python. They serve as a high-level sandbox for advanced algorithms that may be
translated into optimized assembly routines in the future.

## PPO Agent
The `python/ppo_agent.py` script demonstrates a minimal Proximal Policy
Optimization trainer using PyTorch and Gymnasium. It runs on the classic
`CartPole-v1` environment and prints the reward for each episode.

Run the trainer with:
```bash
pip install -r requirements.txt
python python/ppo_agent.py
```

