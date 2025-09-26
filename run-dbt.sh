#!/bin/bash
set -e

# Fetch secrets from AWS Secrets Manager and export as environment variables
# The ECS task role should have permissions to access the secret

# Determine environment from ENVIRONMENT variable or default to dev
ENVIRONMENT=${ENVIRONMENT:-"dev"}
SECRET_NAME=${AWS_SECRET_NAME:-"ellen-young-yt/${ENVIRONMENT}/snowflake/credentials"}
AWS_REGION=${AWS_REGION:-"us-east-2"}

echo "Retrieving Snowflake credentials from AWS Secrets Manager..."
echo "Environment: $ENVIRONMENT"
echo "Secret Name: $SECRET_NAME"
echo "AWS Region: $AWS_REGION"

# Use AWS CLI to get the secret and export each key as an environment variable
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$AWS_REGION" --query SecretString --output text)

# Validate that secret was retrieved
if [ -z "$SECRET_JSON" ] || [ "$SECRET_JSON" = "null" ]; then
    echo "Error: Failed to retrieve secret from AWS Secrets Manager"
    exit 1
fi

export SNOWFLAKE_ACCOUNT=$(echo "$SECRET_JSON" | jq -r '.account // empty')
export SNOWFLAKE_USER=$(echo "$SECRET_JSON" | jq -r '.user // empty')
export SNOWFLAKE_PRIVATE_KEY=$(echo "$SECRET_JSON" | jq -r '.private_key // empty')
export SNOWFLAKE_PRIVATE_KEY_PASSPHRASE=$(echo "$SECRET_JSON" | jq -r '.private_key_passphrase // empty')
export SNOWFLAKE_ROLE=$(echo "$SECRET_JSON" | jq -r '.role // "ACCOUNTADMIN"')
export SNOWFLAKE_DATABASE=$(echo "$SECRET_JSON" | jq -r '.database // empty')
export SNOWFLAKE_WAREHOUSE=$(echo "$SECRET_JSON" | jq -r '.warehouse // empty')
export SNOWFLAKE_SCHEMA=$(echo "$SECRET_JSON" | jq -r '.schema // "PUBLIC"')

# Validate required credentials
if [ -z "$SNOWFLAKE_ACCOUNT" ] || [ -z "$SNOWFLAKE_USER" ] || [ -z "$SNOWFLAKE_PRIVATE_KEY" ]; then
    echo "Error: Missing required Snowflake credentials (account, user, private_key)"
    exit 1
fi

echo "Credentials retrieved successfully for environment: $ENVIRONMENT"

# Set additional environment variables for dbt
export DBT_PROFILES_DIR=${DBT_PROFILES_DIR:-"/var/task/profiles"}
export DBT_PROJECT_DIR=${DBT_PROJECT_DIR:-"/var/task"}

# Determine dbt target based on environment
case "$ENVIRONMENT" in
    "dev")
        export DBT_TARGET="dev"
        ;;
    "staging")
        export DBT_TARGET="test"  # staging uses test target in current setup
        ;;
    "prod")
        export DBT_TARGET="prod"
        ;;
    *)
        export DBT_TARGET="dev"  # default fallback
        ;;
esac

echo "Using dbt target: $DBT_TARGET"

# Run dbt command with proper target
exec dbt "$@" --target "$DBT_TARGET" --profiles-dir "$DBT_PROFILES_DIR"
