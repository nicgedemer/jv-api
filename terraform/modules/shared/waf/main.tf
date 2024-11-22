locals {
  prod = var.environment == "prod" ? true : false
}

resource "aws_wafv2_web_acl" "this" {
  name  = "${var.environment}-${var.waf_name}-WAF"
  scope = var.waf_scope

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority
      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name
          dynamic "rule_action_override" {
            for_each = rule.value.rule_action_override
            content {
              name = rule_action_override.value["name"]
              action_to_use {
                dynamic "allow" {
                  for_each = rule_action_override.value["action_to_use"] == "allow" ? [1] : []
                  content {}
                }
                dynamic "block" {
                  for_each = rule_action_override.value["action_to_use"] == "block" ? [1] : []
                  content {}
                }
                dynamic "count" {
                  for_each = rule_action_override.value["action_to_use"] == "count" ? [1] : []
                  content {}
                }
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 10
    override_action {
      count {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "TARGETED"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-waf"
    sampled_requests_enabled   = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.waf_scope == "REGIONAL" ? 1 : 0

  resource_arn = var.aws_wafv2_web_acl_association_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}


# s3 bucket for waf logs (instead of cloudwatch)
resource "aws_s3_bucket" "bucket" {
  count               = var.environment != "prod" ? 1 : 0
  bucket              = "aws-waf-logs-${var.environment}-jvision"
  object_lock_enabled = false
  tags = {
    resource    = "s3"
    environment = "${var.environment}"
    backup      = (var.environment == "prod") ? "true" : "false"
  }

  force_destroy = true
}

resource "aws_s3_bucket_acl" "bucket" {
  count      = var.environment != "prod" ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.bucket]

  bucket = aws_s3_bucket.bucket[0].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count  = var.environment != "prod" ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  count  = var.environment != "prod" ? 1 : 0
  bucket = aws_s3_bucket.bucket[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# logging (only keep 'drop' connections)

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.environment}-aws-waf-logs"
  retention_in_days = var.environment == "prod" ? 365 : 30
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  log_destination_configs = [aws_s3_bucket.bucket[0].arn]
  resource_arn            = aws_wafv2_web_acl.this.arn

  logging_filter {
    default_behavior = "KEEP"

    filter {
      behavior = (var.environment == "prod") ? "KEEP" : "DROP"

      condition {
        action_condition {
          action = "COUNT"
        }
      }

      requirement = "MEETS_ALL"
    }

    filter {
      behavior = (var.environment == "prod") ? "KEEP" : "DROP"

      condition {
        action_condition {
          action = "ALLOW"
        }
      }

      requirement = "MEETS_ANY"
    }

    filter {
      behavior = "KEEP"

      condition {
        action_condition {
          action = "BLOCK"
        }
      }

      requirement = "MEETS_ANY"
    }
  }

  depends_on = [
    aws_wafv2_web_acl.this,
    aws_cloudwatch_log_group.this
  ]
}