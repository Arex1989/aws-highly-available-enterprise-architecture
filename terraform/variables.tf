variable "aws_region" {
  description = "AWS region used by the enterprise architecture"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI SSO profile used by Terraform"
  type        = string
  default     = "rexmond-admin"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "enterprise"
}
