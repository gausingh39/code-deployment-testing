output "rule_name" {
  description = "Name of the active EventBridge rule (schedule or pattern)"
  value       = local.rule_name
}

output "rule_arn" {
  description = "ARN of the active EventBridge rule"
  value       = local.rule_arn
}

output "sns_role_arns" {
  description = "Map of EventBridge->SNS role ARNs (keyed by map key, e.g., 'sns')"
  value       = { for k, r in aws_iam_role.eventbridge_sns_role : k => r.arn }
  # empty map if enable_sns = false
}

output "sns_policy_arns" {
  description = "Map of EventBridge->SNS policy ARNs (keyed by map key)"
  value       = { for k, p in aws_iam_policy.eventbridge_publish_sns : k => p.arn }
}

output "lambda_targets" {
  description = "Map of lambda targets (keyed by map key -> ARN) added as EventBridge targets"
  value       = { for k, t in aws_cloudwatch_event_target.lambda : k => t.arn }
}
