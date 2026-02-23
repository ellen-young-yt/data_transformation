# Data Transformation Project

A production-ready dbt project with comprehensive infrastructure for data modeling, testing, and deployment. The project is containerized and deployed as a serverless Lambda function on AWS with automated CI/CD pipeline.

## 🏗️ Project Structure

```
data_transformation/
├── .github/workflows/     # CI/CD pipeline configuration
├── terraform/             # Terraform infrastructure as code
│   ├── main.tf            # Main infrastructure configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   ├── modules/           # Reusable Terraform modules
│   │   ├── ecr/           # ECR repository module
│   │   ├── lambda/        # Lambda function module
│   │   └── iam/           # IAM roles and policies module
│   └── environments/      # Environment-specific variable files
│       ├── dev.tfvars     # Development environment variables
│       ├── staging.tfvars # Staging environment variables
│       └── prod.tfvars    # Production environment variables
├── models/                # dbt models (staging, marts, etc.)
├── tests/                 # dbt tests
├── seeds/                 # Reference data
├── macros/                # Reusable SQL macros
├── snapshots/             # Slowly changing dimensions
├── analyses/              # Ad-hoc analyses
├── profiles/              # dbt profiles configuration
├── logs/                  # dbt logs
├── target/                # Compiled SQL and artifacts
├── dbt_project.yml        # dbt project configuration
├── packages.yml           # dbt package dependencies
├── requirements.txt       # Python dependencies
├── Dockerfile             # Lambda-compatible container
├── lambda_handler.py      # Lambda function handler
├── docker-compose.yml     # Docker Compose configuration
├── .pre-commit-config.yaml # Pre-commit hooks
├── .sqlfluff              # SQL linting configuration
├── Makefile               # Development commands
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

- Python 3.12
- Git
- Docker (optional)
- Snowflake account
- AWS account (for Lambda deployment)

### Installation

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd data_transformation
   ```

2. **Set up environment**

   ```bash
   make setup
   ```

3. **Configure environment variables**

   ```bash
   cp env.example .env
   # Edit .env with your Snowflake and AWS credentials
   ```

4. **Install dbt packages**
   ```bash
   make deps
   ```

### Development

1. **Run linting**

   ```bash
   make lint
   ```

2. **Run tests**

   ```bash
   make test
   ```

3. **Run models**

   ```bash
   make run-dev
   ```

4. **Generate documentation**
   ```bash
   make docs
   ```

## 🐳 Docker Usage

### Build and run with Docker

```bash
# Build the image
make docker-build

# Run in development environment
make docker-run-dev

# Run in test environment
make docker-run-test

# Run in production environment
make docker-run
```

## ☁️ AWS Infrastructure Setup

### Using Terraform

1. Navigate to the terraform directory:

   ```bash
   cd terraform
   ```

2. Initialize Terraform:

   ```bash
   terraform init
   ```

3. Plan the deployment (choose dev, staging, or prod):

   ```bash
   terraform plan -var-file=environments/dev.tfvars
   ```

4. Apply the infrastructure:
   ```bash
   terraform apply -var-file=environments/dev.tfvars
   ```

## 🚀 Lambda Function Usage

The Lambda function can be invoked with different parameters:

### Basic Usage

```bash
aws lambda invoke \
  --function-name data-transformation \
  --payload '{"target":"prod","command":"run"}' \
  response.json
```

### Advanced Usage

```bash
aws lambda invoke \
  --function-name data-transformation \
  --payload '{
    "target": "prod",
    "command": "run",
    "full_refresh": true,
    "select": "staging.*",
    "exclude": "staging.raw_*"
  }' \
  response.json
```

### Available Commands

- `run`: Execute dbt models
- `test`: Run dbt tests
- `seed`: Load seed data
- `snapshot`: Create snapshots
- `docs generate`: Generate documentation

## 🔧 Configuration

### Environment Variables

Copy `env.example` to `.env` and configure:

- **Snowflake**: Account, user, password, role, database, warehouse, schema
- **AWS**: Access key, secret key, region, Lambda function name
- **dbt**: Profiles directory, project directory

### dbt Profiles

The project supports three environments:

- `dev`: Development environment
- `test`: Testing environment
- `prod`: Production environment

Configure each environment in `profiles/profiles.yml`.

## 📦 Package Management

This project uses several dbt packages defined in `packages.yml`:

- **dbt-utils**: Essential macros for dbt projects
- **dbt-expectations**: Great Expectations-inspired tests
- **dbt-date**: Date and time utilities
- **dbt-audit-helper**: Utilities for auditing dbt models
- **dbt-codegen**: Generate dbt code

## 🧪 Testing

### Pre-commit Hooks

The project includes pre-commit hooks for:

- SQL linting with SQLFluff
- Python code formatting with Ruff
- YAML validation
- General file checks

### dbt Tests

Run dbt tests with:

```bash
make test
```

## 🚀 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yml`) includes:

1. **Linting and Testing**
   - Pre-commit hooks
   - dbt project validation
   - dbt tests in test environment

2. **Build and Deploy** (main branch only)
   - Docker image build with Lambda-compatible base
   - Push to Amazon ECR
   - Update Lambda function with new image
   - Production dbt run

### Required Secrets

**AWS Secrets Manager Configuration:**

All Snowflake credentials are managed through AWS Secrets Manager using environment-specific secrets:

- **Development**: `ellen-young-yt/dev/snowflake/credentials`
- **Staging**: `ellen-young-yt/staging/snowflake/credentials`
- **Production**: `ellen-young-yt/prod/snowflake/credentials`

Each secret should contain a JSON object with the following keys:

```json
{
  "account": "your_snowflake_account.region",
  "user": "YOUR_USER",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",  # pragma: allowlist secret
  "private_key_passphrase": "optional_passphrase_if_key_is_encrypted",
  "role": "YOUR_ROLE",
  "database": "YOUR_DATABASE",
  "warehouse": "YOUR_WAREHOUSE",
  "schema": "YOUR_SCHEMA"
}
```

**GitHub Repository Secrets (for CI/CD):**

Only AWS credentials are needed as GitHub repository secrets:

**AWS:**

- `AWS_ACCESS_KEY_ID` - AWS access key for deployment
- `AWS_SECRET_ACCESS_KEY` - AWS secret key for deployment
- `AWS_REGION` - AWS region (e.g., us-east-2)

**Note:** With the new Terraform infrastructure, Lambda function and ECR repository names are automatically managed and don't require manual secrets.

### Setting Up Snowflake Key-Pair Authentication

This project uses key-pair authentication for enhanced security. To set this up:

1. **Generate a key pair:**

   ```bash
   openssl genrsa -out snowflake_key.pem 2048
   openssl rsa -in snowflake_key.pem -pubout -out snowflake_key.pub
   ```

2. **Add the public key to your Snowflake user:**

   ```sql
   ALTER USER YOUR_USER SET RSA_PUBLIC_KEY='[public key content without headers]';
   ```

3. **Store the private key in AWS Secrets Manager:**
   - Copy the entire private key (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
   - Store it as the `private_key` field in your AWS secret
   - If the key is encrypted, include the passphrase in `private_key_passphrase`

4. **Test the connection:**
   ```bash
   make test-unit
   ```

## 📚 Available Commands

Run `make help` to see all available commands:

- `make install` - Install Python dependencies
- `make deps` - Install dbt packages
- `make lint` - Run linting
- `make test` - Run dbt tests
- `make run` - Run dbt models
- `make run-dev` - Run in development environment
- `make run-test` - Run in test environment
- `make run-prod` - Run in production environment
- `make docs` - Generate and serve documentation
- `make clean` - Clean dbt artifacts
- `make docker-build` - Build Docker image
- `make docker-run` - Run with Docker

## 🏗️ Model Organization

The project follows dbt best practices:

- **Staging models**: Clean and standardize raw data
- **Marts models**: Business logic and final tables
- **Tests**: Data quality tests
- **Macros**: Reusable SQL logic
- **Snapshots**: Slowly changing dimensions

## 🔒 Security

- Environment variables are used for sensitive data
- Pre-commit hooks prevent committing secrets
- CI/CD pipeline uses GitHub secrets
- Docker images are built securely

## 📖 Documentation

Generate and view documentation:

```bash
make docs
```

This will:

1. Generate dbt documentation
2. Start a local server
3. Open documentation in your browser

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run `make lint` and `make test`
4. Commit with conventional commits
5. Create a pull request

## 📄 License

[Add your license here]

## 🆘 Support

For questions or issues:

1. Check the documentation
2. Review the CI/CD logs
3. Create an issue in the repository
