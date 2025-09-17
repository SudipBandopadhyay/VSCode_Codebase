# Use official Python runtime as a parent image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies required for pyarrow
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source code
COPY . .

# Create non-root user and switch
RUN useradd -m appuser
USER appuser

# Default command
CMD ["python", "exchange_rates.py"]
