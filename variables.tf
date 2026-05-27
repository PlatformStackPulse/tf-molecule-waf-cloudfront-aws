# -----------------------------------------------------------------------------
# Module-Specific Variables
# -----------------------------------------------------------------------------

variable "default_action" {
  type        = string
  description = "Default action for the Web ACL. Valid values: allow, block."
  default     = "allow"
}

variable "web_acl_rules" {
  type        = any
  description = "List of WAF rules for the Web ACL."
  default     = []
}

variable "ip_addresses" {
  type        = list(string)
  description = "List of IP addresses or CIDR blocks for the IP set."
  default     = []
}

variable "ip_address_version" {
  type        = string
  description = "IP address version. Valid values: IPV4, IPV6."
  default     = "IPV4"
}

variable "regex_patterns" {
  type        = list(string)
  description = "List of regex patterns. Empty list skips creation."
  default     = []
}

variable "custom_rule_group_capacity" {
  type        = number
  description = "WCU capacity for custom rule group. 0 to skip."
  default     = 0
}

variable "custom_rules" {
  type        = any
  description = "Custom rules for the rule group."
  default     = []
}

variable "logging_destination_arn" {
  type        = string
  description = "ARN of the logging destination. Null to skip."
  default     = null
}

variable "logging_redacted_fields" {
  type        = any
  description = "Fields to redact from WAF logs."
  default     = []
}
