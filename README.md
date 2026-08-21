# msi-terraform-cloudwatch-oam

Terraform module for **CloudWatch Cross-Account Observability (OAM)**, providing a single-pane
CloudWatch view across MemberSolutions' 15+ AWS accounts.

## Why this exists

CloudWatch does not natively aggregate metrics, logs, alarms, or traces across accounts. AWS's
answer is **CloudWatch Observability Access Manager (OAM)**, which works as a sink/link pair:

- One designated **monitoring account** creates an **OAM sink** — a resource that source accounts
  can send shared data to — plus a **sink policy** naming exactly which source account IDs are
  allowed to link to it and which resource types they may share.
- Every **source account** creates an **OAM link** pointing at that sink's ARN, opting in specific
  resource types (metrics, log groups, traces, ...). Once linked, the monitoring account can see
  and query that source account's CloudWatch data directly, without any data being copied or the
  source account losing ownership of it.

## Dual-role design

This module implements **both** roles from a single codebase, controlled by one input:
`is_monitoring_account`.

| `is_monitoring_account` | Resources created | Account role |
|---|---|---|
| `true` | `aws_oam_sink`, `aws_oam_sink_policy` | The one org-wide monitoring account |
| `false` | `aws_oam_link` | Each of the ~15 source accounts |

This keeps the sink and link definitions (particularly the shared resource-type list) defined
once and reused, so the module is called:

- **once**, in monitor mode, from the monitoring account's Terraform, and
- **once per source account** (~15 times), in link mode, from each source account's Terraform.

The `sink_arn` output of the monitor-mode invocation is the value that must be passed as
`monitoring_account_sink_arn` into every source-account invocation.

> **Org decision required:** which AWS account acts as the monitoring account is an
> organizational decision (e.g. a dedicated "observability" or "shared services" account) that
> must be made — and is out of scope for this module — before the monitor-mode invocation shown
> below can actually be written with real values. Nothing in this module hardcodes a guess at
> which account that is.

## Usage

### 1. Monitoring account (sink)

```hcl
module "cloudwatch_oam_monitoring" {
  source = "git::https://github.com/MemberSolutionsInc/msi-terraform-cloudwatch-oam.git?ref=v0.1.0"

  is_monitoring_account = true
  sink_name              = "msi-org-cloudwatch-oam-sink"

  # All source accounts permitted to link into this sink.
  source_account_ids = [
    "111111111111", # account-a
    "222222222222", # account-b
    # ... one entry per source account
  ]

  # Optional — defaults shown.
  shared_resource_types = [
    "AWS::CloudWatch::Metric",
    "AWS::Logs::LogGroup",
    "AWS::XRay::Trace",
  ]

  tags = {
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

output "cloudwatch_oam_sink_arn" {
  value = module.cloudwatch_oam_monitoring.sink_arn
}
```

The `cloudwatch_oam_sink_arn` output above is the value every source account needs — pass it
along (e.g. via a data source, remote state read, or a shared variable file) into each source
account's invocation as `monitoring_account_sink_arn`.

### 2. Source account (link)

```hcl
module "cloudwatch_oam_link" {
  source = "git::https://github.com/MemberSolutionsInc/msi-terraform-cloudwatch-oam.git?ref=v0.1.0"

  is_monitoring_account       = false
  monitoring_account_sink_arn = "arn:aws:oam:us-east-1:999999999999:sink/abcd1234-...."

  # Optional — defaults shown.
  shared_resource_types = [
    "AWS::CloudWatch::Metric",
    "AWS::Logs::LogGroup",
    "AWS::XRay::Trace",
  ]
  label_template = "$AccountName"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `is_monitoring_account` | `bool` | n/a (required) | `true` for the monitoring account (creates sink + sink policy); `false` for a source account (creates a link). |
| `sink_name` | `string` | `"msi-cloudwatch-oam-sink"` | Name of the OAM sink. Only used when `is_monitoring_account = true`. |
| `source_account_ids` | `list(string)` | `[]` | Account IDs allowed to link to this sink. **Required (non-empty)** when `is_monitoring_account = true`. Unused otherwise. |
| `monitoring_account_sink_arn` | `string` | `""` | ARN of the monitoring account's sink to link to. **Required (non-empty)** when `is_monitoring_account = false`. Unused otherwise. |
| `shared_resource_types` | `list(string)` | `["AWS::CloudWatch::Metric", "AWS::Logs::LogGroup", "AWS::XRay::Trace"]` | Resource types shared cross-account; drives the sink policy `Condition` in monitor mode and `aws_oam_link.resource_types` in link mode. |
| `label_template` | `string` | `"$AccountName"` | Template for the label shown for this source account's data in the monitoring account. Only used when `is_monitoring_account = false`. |
| `tags` | `map(string)` | `{}` | Additional tags applied to created resources. |

## Outputs

| Name | Description |
|---|---|
| `sink_arn` | ARN of the OAM sink. `null` when `is_monitoring_account = false`. Feed this into source accounts' `monitoring_account_sink_arn`. |
| `sink_id` | ID of the OAM sink. `null` when `is_monitoring_account = false`. |
| `sink_policy_arn` | ARN of the OAM sink policy. `null` when `is_monitoring_account = false`. |
| `link_arn` | ARN of the OAM link. `null` when `is_monitoring_account = true`. |
| `link_id` | ID of the OAM link. `null` when `is_monitoring_account = true`. |
| `link_label` | Rendered label of the OAM link. `null` when `is_monitoring_account = true`. |

## Requirements

| Name | Version |
|---|---|
| terraform | `~> 1.0` |
| aws provider | `~> 5.0` |

## Versioning

This module is independently versioned (semver tags, e.g. `v0.1.0`) so that bumping it does not
force a version bump on any of the other split-out CloudWatch observability modules in this org.
