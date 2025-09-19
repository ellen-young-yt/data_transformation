# Use Python 3.12 slim base image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DBT_PROFILES_DIR=/var/task/profiles
ENV DBT_PROJECT_DIR=/var/task

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    awscli \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /var/task

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy dbt project files
COPY . .

# Make run script executable
RUN chmod +x /var/task/run-dbt.sh

# Install dbt packages
RUN dbt deps

# Create profiles directory
RUN mkdir -p /var/task/profiles

# Set the CMD to use our secrets-aware script
CMD ["/var/task/run-dbt.sh", "run", "--profiles-dir", "/var/task/profiles"]
