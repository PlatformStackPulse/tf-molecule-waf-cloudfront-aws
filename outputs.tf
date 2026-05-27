output "web_acl_id" {
  description = "The ID of the Web ACL. Use this in aws_cloudfront_distribution.web_acl_id."
  value       = module.web_acl.id
}

output "web_acl_arn" {
  description = "The ARN of the Web ACL."
  value       = module.web_acl.arn
}

output "ip_set_arn" {
  description = "The ARN of the IP set."
  value       = module.ip_set.arn
}

output "rule_group_arn" {
  description = "The ARN of the custom rule group."
  value       = try(module.rule_group[0].arn, "")
}
