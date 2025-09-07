# Terraform Infrastructure for dbt Data Transformation ECR Repository

This directory contains Terraform configuration to create the ECR repository for the dbt data transformation project.

## Architecture

The Terraform configuration creates:

- **ECR Repository**: Container registry for the dbt Docker image
- **ECR Lifecycle Policy**: Automatic cleanup of old images

**Note**: Lambda function, IAM roles, and other infrastructure should be managed in a separate infrastructure repository.

## Prerequisites

1. **Terraform** (v1.0+)
2. **AWS CLI** (v2.0+)
3. **AWS Account** with appropriate permissions
4. **Docker** (for building and pushing images)

## Setup Instructions

### 1. Configure AWS Credentials

Choose one of the following methods:

#### Option A: AWS CLI Configuration (Recommended)
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., `us-east-2`)
- Default output format (e.g., `json`)

#### Option B: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-2"
```

### 2. Customize Configuration (Optional)

Copy the example variables file and customize:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize:
- AWS region
- Lambda function name
- Memory and timeout settings
- Environment name

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review Changes

```bash
terraform plan
```

This will show you exactly what resources will be created.

### 5. Deploy Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

## Required AWS Permissions

Your AWS credentials need the following permissions:

- **ECR**: `ecr:CreateRepository`, `ecr:DescribeRepositories`, `ecr:PutLifecyclePolicy`, `ecr:PutImageScanningConfiguration`, `ecr:PutEncryptionConfiguration`

## Outputs

After deployment, Terraform will output:

- `ecr_repository_url`: URL for pushing Docker images
- `ecr_repository_arn`: ARN of the ECR repository
- `aws_account_id`: AWS Account ID
- `aws_region`: AWS Region

## Next Steps

After the ECR repository is created:

1. **Build and push Docker image**:
   ```bash
   # From project root
   docker build -t data-transformation .
   aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>
   docker tag data-transformation:latest <ECR_REPOSITORY_URL>:latest
   docker push <ECR_REPOSITORY_URL>:latest
   ```

2. **Update existing Lambda function** (managed in infrastructure repository):
   ```bash
   aws lambda update-function-code --function-name data-transformation --image-uri <ECR_REPOSITORY_URL>:latest
   ```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **Credentials not found**: Ensure AWS credentials are properly configured
2. **Permission denied**: Check that your AWS user has the required permissions
3. **Region mismatch**: Ensure the region in your credentials matches the Terraform configuration

### Useful Commands

```bash
# Check AWS configuration
aws configure list

# Verify Terraform configuration
terraform validate

# View current state
terraform show

# List all resources
terraform state list
```
