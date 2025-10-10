terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
      
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "sns" {
  source = "./infra/modules/sns"
  name   = "${var.project_name}-sns"
}

module "lambda" {
  source          = "./infra/modules/lambda"
  name            = "${var.project_name}-handler"
  handler         = "app/handler.lambda_handler"
  runtime         = "python3.9"
  lambda_zip_path = "${path.module}/lambdas/app.zip"
  sns_topic_arn   = module.sns.topic_arn
}

module "eventbridge" {
  source          = "./infra/modules/eventbridge"
  name            = "${var.project_name}-event"
  lambda_arn      = module.lambda.lambda_arn
  sns_topic_arn   = module.sns.topic_arn
  schedule_expression = "rate(5 minutes)"
}
