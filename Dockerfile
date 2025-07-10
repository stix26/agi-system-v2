# Multi-stage build for optimized AGI System container

# Build stage
FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies with version pinning for reproducibility
RUN apt-get update && apt-get install -y \
    nasm=2.15.05-1 \
    build-essential=12.9ubuntu3 \
    make=4.3-4.1build1 \
    bc=1.07.1-3build1 \
    git=1:2.34.1-1ubuntu1.10 \
    python3=3.10.6-1~22.04 \
    python3-pip=22.0.2+dfsg-1ubuntu0.4 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /build

# Copy only necessary files for build (improves layer caching)
COPY src/ /build/src/
COPY Makefile /build/
COPY requirements.txt /build/

# Install Python dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Build the project with optimizations
RUN make clean && \
    make release JOBS=$(nproc) && \
    strip --strip-unneeded build/agi_system

# Create a minimal runtime stage
FROM ubuntu:22.04 AS runtime

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    libc6=2.35-0ubuntu3.4 \
    python3=3.10.6-1~22.04 \
    python3-pip=22.0.2+dfsg-1ubuntu0.4 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create non-root user for security
RUN groupadd -r agiuser && useradd -r -g agiuser agiuser

# Set working directory
WORKDIR /app

# Copy runtime requirements
COPY requirements.txt /app/
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy built binary and Python components from builder stage
COPY --from=builder /build/build/agi_system /app/agi_system
COPY --from=builder /build/python/ /app/python/

# Copy configuration files
COPY config/ /app/config/

# Set proper ownership
RUN chown -R agiuser:agiuser /app

# Switch to non-root user
USER agiuser

# Expose any ports if needed (none currently)
# EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /app/agi_system --health-check || exit 1

# Add labels for better container management
LABEL maintainer="AGI System Team" \
      version="2.0" \
      description="Optimized AGI System with advanced neural networks" \
      org.opencontainers.image.title="AGI System" \
      org.opencontainers.image.description="Advanced artificial general intelligence system" \
      org.opencontainers.image.vendor="AGI Research" \
      org.opencontainers.image.version="2.0"

# Set environment variables for optimization
ENV AGI_SYSTEM_CONFIG=/app/config/system_config.cfg \
    AGI_SYSTEM_LOG_LEVEL=INFO \
    OMP_NUM_THREADS=4 \
    PYTHONPATH=/app/python \
    PYTHONUNBUFFERED=1

# Default command with optimized flags
CMD ["./agi_system"]
