# -----------------------------------------------------------------------------
# Monitoring account role: create the OAM sink that source accounts link to.
# -----------------------------------------------------------------------------

resource "aws_oam_sink" "this" {
  count = var.is_monitoring_account ? 1 : 0

  name = var.sink_name
  tags = var.tags
}

resource "aws_oam_sink_policy" "this" {
  count = var.is_monitoring_account ? 1 : 0

  sink_identifier = aws_oam_sink.this[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.source_account_ids
        }
        Action = [
          "oam:CreateLink",
          "oam:UpdateLink",
        ]
        Resource = "*"
        Condition = {
          "ForAllValues:StringEquals" = {
            "oam:ResourceTypes" = var.shared_resource_types
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Source account role: link this account's data to a monitoring account's sink.
# -----------------------------------------------------------------------------

resource "aws_oam_link" "this" {
  count = var.is_monitoring_account ? 0 : 1

  label_template  = var.label_template
  resource_types  = var.shared_resource_types
  sink_identifier = var.monitoring_account_sink_arn
  tags            = var.tags
}
