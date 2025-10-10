variable "name" {
  type = string
  default = "global-terraform-backend"
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "bucket" {
  type = string
  description = "S3 bucket name for terraform state (must be globally unique)"
}

variable "dynamodb_table" {
  type = string
  default = "terraform-lock-table"
}


variable "tags" {
  type = map(string)
  default = {}
}

variable "bootstrap_codebuild_role_name" {
  description = "Name of the existing CodeBuild role to attach the backend-bootstrap policy to (e.g. codebuild-service-role)"
  type        = string
  default     = "codebuild-service-role"
}
