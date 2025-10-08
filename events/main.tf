terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# --- EventBridge rules (mutually exclusive) ---
resource "aws_cloudwatch_event_rule" "rule_schedule" {
  count               = var.event_pattern == "" ? 1 : 0
  name                = "${var.name}-schedule"
  schedule_expression = var.schedule_expression
  description         = "Schedule rule created by module ${var.name}"
}

resource "aws_cloudwatch_event_rule" "rule_pattern" {
  count        = var.event_pattern != "" ? 1 : 0
  name         = "${var.name}-pattern"
  event_pattern = var.event_pattern
  description  = "Pattern rule created by module ${var.name}"
}

# --- Local helpers to choose the active rule safely ---
locals {
  rule_name = var.event_pattern == "" ? aws_cloudwatch_event_rule.rule_schedule[0].name : aws_cloudwatch_event_rule.rule_pattern[0].name
  rule_arn  = var.event_pattern == "" ? aws_cloudwatch_event_rule.rule_schedule[0].arn  : aws_cloudwatch_event_rule.rule_pattern[0].arn

  # maps used for for_each so Terraform knows counts at plan time
  sns_map    = var.enable_sns ? { "sns" = var.sns_topic_arn } : {}
  lambda_map = var.enable_lambda ? { "lambda" = var.lambda_arn } : {}
}

# --- IAM role & policy for EventBridge -> SNS (created only if enable_sns = true) ---
resource "aws_iam_role" "eventbridge_sns_role" {
  for_each = local.sns_map

  name = "${var.name}-eb-to-sns-role-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "eventbridge_publish_sns" {
  for_each = local.sns_map

  name = "${var.name}-eb-publish-sns-${each.key}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["sns:Publish"],
        Resource = [each.value]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_eb_sns" {
  for_each = local.sns_map

  role       = aws_iam_role.eventbridge_sns_role[each.key].name
  policy_arn = aws_iam_policy.eventbridge_publish_sns[each.key].arn
}

# --- EventBridge target: Lambda (created only if enable_lambda = true) ---
resource "aws_cloudwatch_event_target" "lambda" {
  for_each = local.lambda_map

  rule      = local.rule_name
  target_id = "lambda-target-${each.key}"
  arn       = each.value
}

# Give EventBridge permission to invoke the Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  for_each = local.lambda_map

  statement_id  = "AllowExecutionFromEventBridge-${var.name}-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "events.amazonaws.com"
  source_arn    = local.rule_arn
}

# --- EventBridge target: SNS (created only if enable_sns = true) ---
resource "aws_cloudwatch_event_target" "sns" {
  for_each = local.sns_map

  rule      = local.rule_name
  target_id = "sns-target-${each.key}"
  arn       = each.value
  role_arn  = aws_iam_role.eventbridge_sns_role[each.key].arn
}
