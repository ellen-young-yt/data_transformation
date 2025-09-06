# Use AWS Lambda Python 3.11 base image
FROM public.ecr.aws/lambda/python:3.11

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DBT_PROFILES_DIR=/var/task/profiles
ENV DBT_PROJECT_DIR=/var/task

# Install system dependencies
RUN yum update -y && \
    yum install -y git curl && \
    yum clean all

# Set work directory
WORKDIR /var/task

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy dbt project files
COPY . .

# Install dbt packages
RUN dbt deps

# Create profiles directory
RUN mkdir -p /var/task/profiles

# Copy lambda handler
COPY lambda_handler.py ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD ["lambda_handler.lambda_handler"]
