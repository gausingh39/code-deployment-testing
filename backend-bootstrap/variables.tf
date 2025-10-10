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
