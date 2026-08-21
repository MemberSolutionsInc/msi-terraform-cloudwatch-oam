variable "is_monitoring_account" {
  description = <<-EOT
    Whether this invocation of the module is for the CloudWatch Observability Access Manager
    (OAM) monitoring (sink) account, or a source (link) account.

    - true  -> creates an aws_oam_sink + aws_oam_sink_policy in this account. Requires
               `source_account_ids` to be set to the list of source accounts allowed to link in.
    - false -> creates an aws_oam_link in this account, pointing at a sink created by the
               monitoring-account invocation of this module. Requires `monitoring_account_sink_arn`
               to be set to that sink's ARN.
  EOT
  type        = bool
}

variable "sink_name" {
  description = "Name of the CloudWatch OAM sink created in the monitoring account. Only used when is_monitoring_account = true."
  type        = string
  default     = "msi-cloudwatch-oam-sink"
}

variable "source_account_ids" {
  description = <<-EOT
    List of AWS account IDs permitted to link to the sink created in this (monitoring) account.

    REQUIRED (must be a non-empty list) when is_monitoring_account = true — the sink policy
    grants oam:CreateLink/oam:UpdateLink only to these accounts. Not used when
    is_monitoring_account = false.
  EOT
  type        = list(string)
  default     = []
}

variable "monitoring_account_sink_arn" {
  description = <<-EOT
    ARN of the CloudWatch OAM sink (in the monitoring account) that this source account should
    link to. This is the `sink_arn` output from the monitoring-account invocation of this same
    module.

    REQUIRED (must be a non-empty string) when is_monitoring_account = false. Not used when
    is_monitoring_account = true.
  EOT
  type        = string
  default     = ""
}

variable "shared_resource_types" {
  description = <<-EOT
    CloudWatch OAM resource types to share cross-account. Used both to build the sink policy's
    Condition (monitoring account) and as the aws_oam_link resource_types (source accounts).
    Valid values: "AWS::CloudWatch::Metric", "AWS::Logs::LogGroup", "AWS::XRay::Trace",
    "AWS::ApplicationInsights::Application", "AWS::InternetMonitor::Monitor".
  EOT
  type        = list(string)
  default     = ["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup", "AWS::XRay::Trace"]
}

variable "label_template" {
  description = "Template used to generate the label shown for this source account's shared data in the monitoring account's console. Only used when is_monitoring_account = false."
  type        = string
  default     = "$AccountName"
}

variable "tags" {
  description = "Additional tags to apply to the sink and/or link resources created by this module."
  type        = map(string)
  default     = {}
}
