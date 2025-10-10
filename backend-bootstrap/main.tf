
resource "aws_s3_bucket" "tfstate" {
  bucket = var.bucket
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = merge(var.tags, { "Name" = var.bucket })
}

resource "aws_s3_bucket_public_access_block" "tfstate_block" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, { "Name" = var.dynamodb_table })
}

# Optionally store outputs in SSM Parameter Store so other jobs can discover them
resource "aws_ssm_parameter" "backend_bucket" {
  name        = "/terraform-backend/${var.name}/bucket"
  type        = "String"
  value       = aws_s3_bucket.tfstate.id
  overwrite   = true
  tags        = var.tags
}

resource "aws_ssm_parameter" "backend_dynamodb" {
  name      = "/terraform-backend/${var.name}/dynamodb_table"
  type      = "String"
  value     = aws_dynamodb_table.locks.name
  overwrite = true
  tags      = var.tags
}

resource "aws_ssm_parameter" "backend_region" {
  name      = "/terraform-backend/${var.name}/region"
  type      = "String"
  value     = var.region
  overwrite = true
  tags      = var.tags
}



output "bucket" {
  description = "S3 bucket used for Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "dynamodb_table" {
  description = "DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.locks.name
}

output "region" {
  description = "Region where backend resources live"
  value       = var.region
}