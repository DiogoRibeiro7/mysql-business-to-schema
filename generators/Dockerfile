# Dockerfile for MySQL Business-to-Schema Data Generators
FROM python:3.10-slim

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

# Copy generator files (will be overridden by volume mount)
COPY . /app/

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV OUTPUT_DIR=/app/output
ENV GENERATOR_MODE=test

# Default command (can be overridden)
CMD ["python", "generator.py"]