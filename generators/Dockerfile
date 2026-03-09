# Dockerfile for MySQL Business-to-Schema Data Generators
FROM python:3.14-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    faker==20.1.0 \
    numpy==1.26.2 \
    pandas==2.1.4 \
    pyyaml==6.0.1 \
    mysql-connector-python==8.2.0 \
    psycopg2-binary==2.9.9 \
    pymongo==4.6.1 \
    redis==5.0.1

# Create output directory
RUN mkdir -p /app/output /app/data

# Create non-root runtime user
RUN groupadd --gid 10001 appuser && useradd --uid 10001 --gid 10001 --create-home --shell /bin/bash appuser

# Copy generator files (will be overridden by volume mount)
COPY . /app/
RUN chown -R appuser:appuser /app

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV OUTPUT_DIR=/app/output
ENV GENERATOR_MODE=test

# Basic health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python --version || exit 1

# Drop root privileges
USER appuser

# Default command (can be overridden)
CMD ["python", "generator.py"]
