#!/bin/bash
set -e

# Fetch secrets from AWS Secrets Manager and export as environment variables
# The ECS task role should have permissions to access the secret

SECRET_NAME=${AWS_SECRET_NAME:-"snowflake/data-transformation/credentials"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo "Retrieving Snowflake credentials from AWS Secrets Manager..."

# Use AWS CLI to get the secret and export each key as an environment variable
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$AWS_REGION" --query SecretString --output text)

export SNOWFLAKE_ACCOUNT=$(echo "$SECRET_JSON" | jq -r '.account // empty')
export SNOWFLAKE_USER=$(echo "$SECRET_JSON" | jq -r '.user // empty')
export SNOWFLAKE_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password // empty')
export SNOWFLAKE_ROLE=$(echo "$SECRET_JSON" | jq -r '.role // "ACCOUNTADMIN"')
export SNOWFLAKE_DATABASE=$(echo "$SECRET_JSON" | jq -r '.database // empty')
export SNOWFLAKE_WAREHOUSE=$(echo "$SECRET_JSON" | jq -r '.warehouse // empty')
export SNOWFLAKE_SCHEMA=$(echo "$SECRET_JSON" | jq -r '.schema // "PUBLIC"')

echo "Credentials retrieved successfully"

# Run dbt command
exec dbt "$@"