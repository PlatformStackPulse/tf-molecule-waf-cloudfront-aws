# Unit Tests — tf-molecule-waf-cloudfront-aws
#
# These tests use a mocked AWS provider — no real AWS calls are made.
# Run with:         terraform test -test-directory=tests/unit
# Run verbose:      terraform test -test-directory=tests/unit -verbose
# Run specific:     terraform test -test-directory=tests/unit -run "creates_when_enabled"
#
# NOTE: Assertions target plan-KNOWN values only (the tf-label id string and
# input pass-throughs). Computed WAF arn/id values are unknown under a mock
# provider, so they are never asserted on directly.

mock_provider "aws" {}

variables {
  # tf-label context inputs
  namespace = "eg"
  stage     = "test"
  name      = "thing"

  # Module inputs (valid sample values)
  default_action     = "allow"
  ip_addresses       = ["203.0.113.0/24", "198.51.100.10/32"]
  ip_address_version = "IPV4"
  regex_patterns     = ["^/admin", ".*\\.php$"]
}

# ---------------------------------------------------------------------------
# Test: Module composes the WAF stack when enabled (default)
# ---------------------------------------------------------------------------
run "creates_when_enabled" {
  command = plan

  assert {
    condition     = module.this.id == "eg-test-thing"
    error_message = "tf-label id should be 'eg-test-thing' from namespace/stage/name."
  }

  assert {
    condition     = module.this.enabled == true
    error_message = "Module should be enabled by default."
  }

  assert {
    condition     = length(module.regex_pattern_set) == 1
    error_message = "Regex pattern set should be created when regex_patterns is non-empty."
  }
}

# ---------------------------------------------------------------------------
# Test: Optional sub-modules are skipped when their inputs are empty
# ---------------------------------------------------------------------------
run "optional_submodules_skipped" {
  command = plan

  variables {
    regex_patterns             = []
    custom_rule_group_capacity = 0
    logging_destination_arn    = null
  }

  assert {
    condition     = length(module.regex_pattern_set) == 0
    error_message = "Regex pattern set should be skipped when regex_patterns is empty."
  }

  assert {
    condition     = length(module.rule_group) == 0
    error_message = "Rule group should be skipped when capacity is 0."
  }

  assert {
    condition     = length(module.logging) == 0
    error_message = "Logging should be skipped when logging_destination_arn is null."
  }
}

# ---------------------------------------------------------------------------
# Test: Disabled context produces an empty tf-label id (nothing named/created)
# ---------------------------------------------------------------------------
run "disabled_creates_nothing" {
  command = plan

  variables {
    enabled = false
  }

  assert {
    condition     = module.this.enabled == false
    error_message = "Context should propagate enabled = false."
  }

  assert {
    condition     = module.this.id == ""
    error_message = "tf-label id should be empty when the module is disabled."
  }
}
