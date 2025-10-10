variable "aws_region" {
  description = "AWS region to operate in"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional named AWS CLI profile to use (local dev). Leave empty for env credentials or IAM role."
  type        = string
  default     = ""
}

variable "assume_role_arn" {
  description = "Optional IAM role ARN to assume for provisioning (useful in CI or cross-account)"
  type        = string
  default     = ""
}

provider "aws" {
  region                  = var.aws_region
  shared_credentials_file = var.aws_profile != "" ? pathexpand("~/.aws/credentials") : null
  profile                 = var.aws_profile != "" ? var.aws_profile : null

  # When running in CI, you may set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN instead of profile.
  assume_role {
    role_arn     = var.assume_role_arn != "" ? var.assume_role_arn : null
    session_name = var.assume_role_arn != "" ? "terraform-session-${substr(md5(timestamp()),0,6)}" : null
  }

  # Helpful: increase retries to soften transient API errors
  max_retries = 5
  # Optional: configure endpoints_override for local testing (commented)
  # endpoints {
  #   sts = "https://sts.amazonaws.com"
  # }
}
