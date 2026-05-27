# -----------------------------------------------------
# Molecule: WAF CloudFront
# Composes WAF atoms for CloudFront protection.
# Scope: CLOUDFRONT (must be us-east-1)
# Note: No association module - CloudFront uses web_acl_id directly.
# -----------------------------------------------------

# --- IP Set (allowlist/blocklist) ---
module "ip_set" {
  source = "git::https://github.com/PlatformStackPulse/tf-atom-wafv2-ip-set-aws.git?ref=v1.1.0"

  context            = module.this.context
  scope              = "CLOUDFRONT"
  ip_address_version = var.ip_address_version
  addresses          = var.ip_addresses
  description        = "IP set for ${module.this.id}"
}

# --- Regex Pattern Set (optional) ---
module "regex_pattern_set" {
  source = "git::https://github.com/PlatformStackPulse/tf-atom-wafv2-regex-pattern-set-aws.git?ref=v1.0.0"

  count = length(var.regex_patterns) > 0 ? 1 : 0

  context             = module.this.context
  scope               = "CLOUDFRONT"
  regular_expressions = var.regex_patterns
  description         = "Regex patterns for ${module.this.id}"
}

# --- Rule Group (custom rules) ---
module "rule_group" {
  source = "git::https://github.com/PlatformStackPulse/tf-atom-wafv2-rule-group-aws.git?ref=v1.1.0"

  count = var.custom_rule_group_capacity > 0 ? 1 : 0

  context  = module.this.context
  scope    = "CLOUDFRONT"
  capacity = var.custom_rule_group_capacity
  rules    = var.custom_rules

  depends_on = [module.ip_set]
}

# --- Web ACL ---
module "web_acl" {
  source = "git::https://github.com/PlatformStackPulse/tf-atom-wafv2-web-acl-aws.git?ref=v1.1.0"

  context        = module.this.context
  scope          = "CLOUDFRONT"
  default_action = var.default_action
  rules          = var.web_acl_rules
  description    = "CloudFront WAF Web ACL for ${module.this.id}"

  depends_on = [module.ip_set, module.rule_group]
}

# --- Logging (optional) ---
module "logging" {
  source = "git::https://github.com/PlatformStackPulse/tf-atom-wafv2-web-acl-logging-aws.git?ref=v1.1.0"

  count = var.logging_destination_arn != null ? 1 : 0

  context                 = module.this.context
  resource_arn            = module.web_acl.arn
  log_destination_configs = [var.logging_destination_arn]
  redacted_fields         = var.logging_redacted_fields

  depends_on = [module.web_acl]
}
