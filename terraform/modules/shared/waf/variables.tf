variable "environment" {}
variable "waf_name" {}

variable "aws_wafv2_web_acl_association_arn" {
  default = ""
}

variable "waf_scope" {
  default = "REGIONAL"
}

variable "default_action" {
  default = "allow"
}

variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    vendor_name     = string
    version         = optional(string)
    rule_action_override = list(object({
      name          = string
      action_to_use = string
    }))
  }))
  description = "Managed WAF rules"
  default = [
    {
      name                 = "AWSManagedRulesCommonRuleSet"
      priority             = 50
      vendor_name          = "AWS"
      override_action      = "count"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesKnownBadInputsRuleSet"
      priority             = 60
      vendor_name          = "AWS"
      override_action      = "count"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesAmazonIpReputationList"
      priority             = 70
      vendor_name          = "AWS"
      override_action      = "none"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesLinuxRuleSet"
      priority             = 80
      vendor_name          = "AWS"
      override_action      = "count"
      rule_action_override = []
    },
    {
      name                 = "AWSManagedRulesSQLiRuleSet"
      priority             = 100
      vendor_name          = "AWS"
      override_action      = "count"
      rule_action_override = []
    }
  ]
}