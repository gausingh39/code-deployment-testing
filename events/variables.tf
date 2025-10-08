variable "name" {
  description = "Base name prefix for resources created by this module"
  type        = string
}

variable "schedule_expression" {
  description = "Schedule expression for EventBridge rule (rate() or cron()). Used when event_pattern is empty."
  type        = string
  default     = "rate(5 minutes)"
}

variable "event_pattern" {
  description = <<EOF
Optional EventBridge event pattern (JSON string). If non-empty, this module creates a pattern rule instead of a schedule.
Provide a JSON string (escaped) e.g. "{\"source\":[\"aws.ec2\"]}"
EOF
  type    = string
  default = ""
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic to be targetted by EventBridge. If empty and enable_sns=false, no SNS target/role is created."
  type        = string
  default     = ""
}

variable "lambda_arn" {
  description = "ARN of the Lambda function to be targetted by EventBridge. If empty and enable_lambda=false, no Lambda target is created."
  type        = string
  default     = ""
}

variable "enable_sns" {
  description = "Set to true to create resources for EventBridge->SNS integration (role, policy, target). Useful when you provide sns_topic_arn or want to enable SNS target."
  type        = bool
  default     = false
}

variable "enable_lambda" {
  description = "Set to true to create resources for EventBridge->Lambda integration (target + permission). Useful when you provide lambda_arn or want to enable Lambda target."
  type        = bool
  default     = false
}
