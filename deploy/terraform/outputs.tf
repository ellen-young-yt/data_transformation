# Outputs for dbt data transformation ECR repository

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.data_transformation.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.data_transformation.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}
