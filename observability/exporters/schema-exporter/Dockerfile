FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY exporter.py .

# Create non-root user
RUN useradd -m -u 1000 exporter && chown -R exporter:exporter /app
USER exporter

# Expose metrics port
EXPOSE 9105

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9105/health || exit 1

# Start exporter
CMD ["python", "exporter.py"]