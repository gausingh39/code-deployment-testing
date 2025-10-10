# IAM policy used by bootstrap CodeBuild role (managed policy)
resource "aws_iam_policy" "backend_bootstrap_policy" {
  name        = "${replace(var.name, "/", "-")}-backend-bootstrap-policy"
  description = "Permissions for bootstrap CodeBuild to create backend S3, DynamoDB lock, and write SSM params"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowS3BackendManagement",
        Effect = "Allow",
        Action = [
          "s3:CreateBucket",
          "s3:PutBucketVersioning",
          "s3:PutBucketPublicAccessBlock",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketAcl",
          "s3:PutBucketTagging",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket}",
          "arn:aws:s3:::${var.bucket}/*"
        ]
      },
      {
        Sid = "AllowDynamoDBLockTableManagement",
        Effect = "Allow",
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:DeleteTable",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table}"
        ]
      },
      {
        Sid = "AllowSSMForBackendDiscovery",
        Effect = "Allow",
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:DeleteParameter"
        ],
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/terraform-backend/${var.name}/*",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/terraform-backend/${var.name}"
        ]
      },
      {
        Sid = "AllowCloudWatchLogsAndMisc",
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "iam:PassRole"
        ],
        Resource = ["*"]
      }
    ]
  })
}

# Attach the managed policy to an existing role
resource "aws_iam_role_policy_attachment" "attach_backend_bootstrap_policy" {
  role       = var.bootstrap_codebuild_role_name
  policy_arn = aws_iam_policy.backend_bootstrap_policy.arn
}

# helper data source to determine current account id used in policy generation
data "aws_caller_identity" "current" {}



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