# Use slim Python 3.11
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app ./app

# Expose metrics port (optional, Prometheus)
EXPOSE 8002

# Start consumer
# -u : unbuffered output for real-time logs in ECS
CMD ["python", "-u", "-m", "app.consumer"]
