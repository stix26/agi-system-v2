# Example script to generate random input data
import random

with open("examples/generated_input.txt", "w") as f:
    for _ in range(10):
        f.write(f"{random.randint(0, 10)} {random.randint(0, 10)}\n")
