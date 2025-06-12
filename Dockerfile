# Use Ubuntu as base image
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    nasm \
    build-essential \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy source files and build configuration
COPY src/ /app/src/
COPY Makefile /app/

# Build the project
RUN make

# Command to run the AGI system
CMD ["./build/agi_system"]
