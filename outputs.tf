output "sink_arn" {
  description = "ARN of the CloudWatch OAM sink created in the monitoring account. Null when is_monitoring_account = false. Pass this value as `monitoring_account_sink_arn` into every source account's invocation of this module."
  value       = try(aws_oam_sink.this[0].arn, null)
}

output "sink_id" {
  description = "ID of the CloudWatch OAM sink created in the monitoring account. Null when is_monitoring_account = false."
  value       = try(aws_oam_sink.this[0].id, null)
}

output "sink_policy_arn" {
  description = "ARN of the OAM sink policy attached to the sink. Null when is_monitoring_account = false."
  value       = try(aws_oam_sink_policy.this[0].arn, null)
}

output "link_arn" {
  description = "ARN of the CloudWatch OAM link created in this source account. Null when is_monitoring_account = true."
  value       = try(aws_oam_link.this[0].arn, null)
}

output "link_id" {
  description = "ID of the CloudWatch OAM link created in this source account. Null when is_monitoring_account = true."
  value       = try(aws_oam_link.this[0].id, null)
}

output "link_label" {
  description = "Rendered label of the CloudWatch OAM link, as shown in the monitoring account. Null when is_monitoring_account = true."
  value       = try(aws_oam_link.this[0].label, null)
}
