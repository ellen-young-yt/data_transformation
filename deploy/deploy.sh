#!/bin/bash

# Complete Deployment Script
# This script handles the complete deployment of the dbt data transformation project

set -e

# Configuration
AWS_REGION=${AWS_DEFAULT_REGION:-us-east-1}
LAMBDA_FUNCTION_NAME=${AWS_LAMBDA_FUNCTION_NAME:-data-transformation}
ECR_REPOSITORY_NAME=${ECR_REPOSITORY_NAME:-data-transformation}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "Starting deployment of dbt data transformation project..."
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo "Lambda Function: $LAMBDA_FUNCTION_NAME"
echo "ECR Repository: $ECR_REPOSITORY_NAME"

# Step 1: Setup ECR repository
echo "Step 1: Setting up ECR repository..."
./deploy/ecr-setup.sh

# Step 2: Build and push Docker image
echo "Step 2: Building and pushing Docker image..."
docker build -t $ECR_REPOSITORY_NAME:latest .
docker tag $ECR_REPOSITORY_NAME:latest $ECR_REGISTRY/$ECR_REPOSITORY_NAME:latest

# Get ECR login token
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Push image to ECR
docker push $ECR_REGISTRY/$ECR_REPOSITORY_NAME:latest

# Step 3: Setup Lambda function
echo "Step 3: Setting up Lambda function..."
./deploy/lambda-setup.sh

# Step 4: Update Lambda function with new image
echo "Step 4: Updating Lambda function with new image..."
aws lambda update-function-code \
    --function-name $LAMBDA_FUNCTION_NAME \
    --image-uri $ECR_REGISTRY/$ECR_REPOSITORY_NAME:latest

echo "Deployment complete!"
echo ""
echo "Lambda function is ready to use:"
echo "Function ARN: arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:$LAMBDA_FUNCTION_NAME"
echo ""
echo "To test the function:"
echo "aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload '{\"target\":\"prod\",\"command\":\"run\"}' response.json"
