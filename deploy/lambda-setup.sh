#!/bin/bash

# Lambda Function Setup Script
# This script creates the Lambda function for the dbt data transformation project

set -e

# Configuration
AWS_REGION=${AWS_DEFAULT_REGION:-us-east-1}
LAMBDA_FUNCTION_NAME=${AWS_LAMBDA_FUNCTION_NAME:-data-transformation}
ECR_REPOSITORY_NAME=${ECR_REPOSITORY_NAME:-data-transformation}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY_NAME:latest"

# IAM Role Configuration
LAMBDA_ROLE_NAME="${LAMBDA_FUNCTION_NAME}-role"
LAMBDA_POLICY_NAME="${LAMBDA_FUNCTION_NAME}-policy"

echo "Setting up Lambda function for dbt data transformation..."
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo "Lambda Function: $LAMBDA_FUNCTION_NAME"
echo "ECR Image URI: $ECR_IMAGE_URI"

# Create IAM role for Lambda
echo "Creating IAM role for Lambda..."
aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }' || echo "Role already exists"

# Create IAM policy for Lambda
echo "Creating IAM policy for Lambda..."
aws iam create-policy \
    --policy-name $LAMBDA_POLICY_NAME \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": "arn:aws:logs:*:*:*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "secretsmanager:GetSecretValue"
                ],
                "Resource": "arn:aws:secretsmanager:*:*:secret:*"
            }
        ]
    }' || echo "Policy already exists"

# Attach policies to role
echo "Attaching policies to role..."
aws iam attach-role-policy \
    --role-name $LAMBDA_ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
    --role-name $LAMBDA_ROLE_NAME \
    --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$LAMBDA_POLICY_NAME

# Wait for role to be ready
echo "Waiting for IAM role to be ready..."
sleep 10

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE_NAME --query 'Role.Arn' --output text)

# Create Lambda function
echo "Creating Lambda function..."
aws lambda create-function \
    --function-name $LAMBDA_FUNCTION_NAME \
    --package-type Image \
    --code ImageUri=$ECR_IMAGE_URI \
    --role $ROLE_ARN \
    --timeout 900 \
    --memory-size 1024 \
    --environment Variables='{
        "DBT_PROFILES_DIR": "/var/task/profiles",
        "DBT_PROJECT_DIR": "/var/task"
    }' || echo "Function already exists"

# Update function configuration
echo "Updating Lambda function configuration..."
aws lambda update-function-configuration \
    --function-name $LAMBDA_FUNCTION_NAME \
    --timeout 900 \
    --memory-size 1024 \
    --environment Variables='{
        "DBT_PROFILES_DIR": "/var/task/profiles",
        "DBT_PROJECT_DIR": "/var/task"
    }'

echo "Lambda function setup complete!"
echo "Function ARN: arn:aws:lambda:$AWS_REGION:$AWS_ACCOUNT_ID:function:$LAMBDA_FUNCTION_NAME"
echo ""
echo "To test the function:"
echo "aws lambda invoke --function-name $LAMBDA_FUNCTION_NAME --payload '{\"target\":\"prod\",\"command\":\"run\"}' response.json"
