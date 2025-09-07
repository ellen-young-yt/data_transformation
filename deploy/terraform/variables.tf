# Variables for dbt data transformation ECR repository

variable "aws_region" {
  description = "AWS region for ECR repository"
  type        = string
  default     = "us-east-2"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "data-transformation"
}
