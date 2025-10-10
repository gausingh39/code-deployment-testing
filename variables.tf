variable "aws_region" {
  description = "AWS region where resources are created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Base name for project resources"
  type        = string
  default     = "code-deployment-testing"
}
