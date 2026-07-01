# tf-molecule-waf-cloudfront-aws

[![Terraform Format](https://img.shields.io/badge/terraform-fmt-blue?logo=terraform)](https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws/actions)
[![Terraform Validate](https://img.shields.io/badge/terraform-validate-blue?logo=terraform)](https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws/actions)
[![TFLint](https://img.shields.io/badge/tflint-passing-brightgreen?logo=terraform)](https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws/actions)
[![Terraform Test](https://img.shields.io/badge/tests-3%20passed-brightgreen?logo=terraform)](https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws/actions)
[![Security Scan](https://img.shields.io/badge/trivy-passing-brightgreen?logo=aqua)](https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws/actions)
[![Conventional Commits](https://img.shields.io/badge/commits-conventional-blue?logo=conventionalcommits)](https://conventionalcommits.org)
[![Documentation](https://img.shields.io/badge/docs-terraform--docs-blue?logo=readthedocs)](https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws/actions)
[![License](https://img.shields.io/badge/license-MIT-blue?logo=opensourceinitiative)](LICENSE)

Terraform **molecule** that composes AWS WAFv2 atoms into a complete, ready-to-attach
Web ACL for **Amazon CloudFront**. It wires an IP set, an optional regex pattern set, an
optional custom rule group, the Web ACL itself, and optional logging — all pinned to the
`CLOUDFRONT` scope (`us-east-1`) — behind a single `tf-label`-driven interface.

## Features

- **CloudFront-scoped Web ACL** — All atoms are created with `scope = "CLOUDFRONT"`; the `web_acl_id` output drops straight into `aws_cloudfront_distribution.web_acl_id` (no association resource needed).
- **IP allow/block set** — Provide IPv4 or IPv6 CIDRs via `ip_addresses` / `ip_address_version` for a reusable IP set.
- **Optional regex pattern set** — Supply `regex_patterns` to create a regex pattern set; an empty list skips it.
- **Optional custom rule group** — Set `custom_rule_group_capacity > 0` with `custom_rules` to attach a bespoke rule group; `0` skips it.
- **Configurable default action + rules** — `default_action` (`allow`/`block`) and `web_acl_rules` shape the Web ACL.
- **Optional WAF logging** — Set `logging_destination_arn` (with optional `logging_redacted_fields`) to enable Web ACL logging; `null` skips it.
- **tf-label context chaining** — Standard `namespace`/`stage`/`name`/`enabled`/`tags` interface; `enabled = false` disables the whole stack.
- **Quality gates** — `terraform test` (mock provider), TFLint, Trivy IaC scan, terraform-docs, and pre-commit hooks in CI.

## CI Pipeline

When a PR is merged to `main`, all CI checks run automatically. On success, a release is created:

```
PR merged → CI runs → All pass → Auto-tag (semver) → GitHub Release
```

| Check | Description | Status |
|-------|-------------|--------|
| Format | `terraform fmt -check -recursive` | Must pass |
| Validate | `terraform validate` on module + examples | Must pass |
| Lint | TFLint with AWS ruleset (preset "all") | Must pass |
| Test | `terraform test` with mock providers | Must pass |
| Security | Trivy IaC scan (HIGH/CRITICAL) | Must pass |
| Docs | terraform-docs freshness check | Must pass |
| Commit Lint | Conventional commit format (PR only) | Must pass |

## Quick Start

### Create a New Module

```bash
# Create repo from template (name MUST follow: terraform-<PROVIDER>-<NAME>)
gh repo create PlatformStackPulse/terraform-aws-my-module --template PlatformStackPulse/Terraform-module-base-template --public

# Clone
git clone git@github.com:PlatformStackPulse/terraform-aws-my-module.git
cd terraform-aws-my-module

# Install tools and hooks
make dev-setup
make hooks

# Run all checks
make all
```

### Customise the Template

1. Replace the example S3 resources in `main.tf` with your actual resources
2. Update `variables.tf`, `outputs.tf`, and `versions.tf`
3. Write tests in `tests/unit/main_test.tftest.hcl`
4. Update `examples/complete/` with real usage
5. Update `.github/CODEOWNERS`
6. Update this `README.md`

See [TEMPLATE_GUIDE.md](TEMPLATE_GUIDE.md) for detailed instructions.

## Usage

> **Scope:** this molecule creates `CLOUDFRONT`-scoped WAF resources, which **must** live
> in `us-east-1`. Configure the `aws` provider accordingly.

```hcl
provider "aws" {
  region = "us-east-1"
}

module "cloudfront_waf" {
  source = "git::https://github.com/PlatformStackPulse/tf-molecule-waf-cloudfront-aws.git?ref=v1.0.0"

  # tf-label context
  namespace = "eg"
  stage     = "prod"
  name      = "edge"

  # Web ACL
  default_action = "allow"
  web_acl_rules  = [] # add managed / rate-based / custom rule blocks here

  # IP set (optional)
  ip_addresses       = ["203.0.113.0/24"]
  ip_address_version = "IPV4"

  # Regex pattern set (optional — empty list skips it)
  regex_patterns = ["^/admin"]

  # Logging (optional — null skips it)
  logging_destination_arn = "arn:aws:logs:us-east-1:111122223333:log-group:aws-waf-logs-edge"

  tags = {
    Project = "example"
    Owner   = "platform-engineering"
  }
}

resource "aws_cloudfront_distribution" "this" {
  # ...
  web_acl_id = module.cloudfront_waf.web_acl_id
}
```

## Module Structure

```
├── main.tf           # Primary resource definitions
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── versions.tf       # Terraform and provider version constraints
├── locals.tf         # Local values and naming conventions
├── data.tf           # Data sources
├── examples/         # Usage examples for consumers
│   └── complete/     # Full-featured example
├── tests/            # Terraform native tests
│   ├── unit/         # Unit tests with mock providers
│   └── integration/  # Integration tests (real AWS)
├── .github/          # GitHub Actions + templates
├── scripts/          # Automation scripts
└── Makefile          # Build automation
```

## Make Targets

```
make help              Show all targets
make init              Initialize the module
make fmt               Format all Terraform files
make fmt-check         Check formatting (CI mode)
make validate          Validate the module
make lint              Run TFLint
make test              Run all tests
make test-unit         Run unit tests only
make test-integration  Run integration tests
make security          Run Trivy security scan
make docs              Generate terraform-docs
make clean             Remove .terraform dirs
make all               Run all checks
make dev-setup         Install development tools
make hooks             Install pre-commit hooks
make changelog         Regenerate CHANGELOG.md
make version           Show current version
make release           Create version tag (BUMP=patch|minor|major)
```

## Publishing

### Terraform Registry (Public)

The [Terraform Registry](https://registry.terraform.io) automatically publishes new versions when you create a GitHub Release:

1. **Name your repo** following the convention: `terraform-<PROVIDER>-<NAME>` (e.g., `terraform-aws-vpc`)
2. **Connect** at [registry.terraform.io/github/create](https://registry.terraform.io/github/create)
3. **Tag and release** — every semver tag (`v1.0.0`) is auto-published

### Terraform Cloud / Enterprise (Private)

1. Connect your VCS provider in TFC/TFE settings
2. Create a Module in the private registry pointing to this repo
3. Semver tags trigger automatic version publication

### JFrog Artifactory

Set these repository variables/secrets in GitHub:
- `ARTIFACTORY_ENABLED` = `true` (variable)
- `ARTIFACTORY_URL` — e.g., `https://myorg.jfrog.io/artifactory` (variable)
- `ARTIFACTORY_REPO` — e.g., `terraform-modules` (variable)
- `ARTIFACTORY_TOKEN` (secret)

### GitLab Terraform Registry

To publish to GitLab, add a `publish-gitlab` job in `.github/workflows/auto-release.yml` and set:
- `GITLAB_TOKEN` (secret)
- `GITLAB_PROJECT_ID` (variable)

## CI/CD Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push (all branches), PR to main, manual | Format, validate, lint, test, security |
| `auto-release.yml` | CI passes on main | Auto-tag stable release + GitHub Release + artifacts |
| `preview-release.yml` | CI passes on feature branch | Create pre-release with branch version |
| `codeql.yml` | Weekly + push main | SAST security analysis |
| `dependencies.yml` | Weekly | Check for provider updates |
| `changelog.yml` | Push main | Auto-update CHANGELOG.md |
| `version-bump.yml` | Manual | Bump patch/minor/major version |

## Git & Release Strategy

This template follows **Trunk-Based Development with Preview Artifacts**.

### Versioning

All versions follow [Semantic Versioning 2.0.0](https://semver.org/):

| Type | Format | Example | Source |
|------|--------|---------|--------|
| Stable | `MAJOR.MINOR.PATCH` | `v1.4.0` | main branch |
| Preview | `MAJOR.MINOR.PATCH-BRANCH.RUN` | `v1.5.0-feat-add-ecs.12` | feature branch |

### Release Flow

```
Developer creates feature branch (feat/*, fix/*, feature/*)
        ↓
Push triggers CI (format, validate, lint, test, security)
        ↓
CI passes → Preview Release created (pre-release tag)
        ↓
Other branches/environments can consume preview version
        ↓
PR merged to main
        ↓
CI runs on main → Auto Release creates stable tag + GitHub Release + artifacts
```

### Consuming Modules

**Stable release (production):**
```hcl
module "this" {
  source = "github.com/ORG/REPO?ref=v1.4.0"
}
```

**Preview release (testing/integration):**
```hcl
module "this" {
  source = "github.com/ORG/REPO?ref=v1.5.0-feat-add-ecs.12"
}
```

### Version Bump Rules (Conventional Commits)

| Commit prefix | Bump | Example |
|---------------|------|---------|
| `feat!:` or `BREAKING CHANGE` | Major | `v1.0.0` → `v2.0.0` |
| `feat:` | Minor | `v1.4.0` → `v1.5.0` |
| `fix:`, `docs:`, `chore:`, etc. | Patch | `v1.4.0` → `v1.4.1` |

## Pre-Commit Hooks

Installed via `make hooks`. Runs on every commit:

- `terraform_fmt` — Format check
- `terraform_validate` — Syntax validation
- `terraform_tflint` — Linting with AWS rules
- `terraform_docs` — Auto-generate documentation
- `terraform_trivy` — Security scanning (HIGH/CRITICAL)
- `gitlint` — Conventional commit message validation

## Module Documentation

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0 |

### Providers

No providers.

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ip_set"></a> [ip\_set](#module\_ip\_set) | git::https://github.com/PlatformStackPulse/tf-atom-wafv2-ip-set-aws.git | v1.1.0 |
| <a name="module_logging"></a> [logging](#module\_logging) | git::https://github.com/PlatformStackPulse/tf-atom-wafv2-web-acl-logging-aws.git | v1.1.0 |
| <a name="module_regex_pattern_set"></a> [regex\_pattern\_set](#module\_regex\_pattern\_set) | git::https://github.com/PlatformStackPulse/tf-atom-wafv2-regex-pattern-set-aws.git | v1.1.0 |
| <a name="module_rule_group"></a> [rule\_group](#module\_rule\_group) | git::https://github.com/PlatformStackPulse/tf-atom-wafv2-rule-group-aws.git | v1.1.0 |
| <a name="module_this"></a> [this](#module\_this) | git::https://github.com/PlatformStackPulse/tf-label.git | v1.0.0 |
| <a name="module_web_acl"></a> [web\_acl](#module\_web\_acl) | git::https://github.com/PlatformStackPulse/tf-atom-wafv2-web-acl-aws.git | v1.1.0 |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes and tags, which are merged. | <pre>object({<br/>    enabled             = optional(bool, true)<br/>    namespace           = optional(string, null)<br/>    tenant              = optional(string, null)<br/>    environment         = optional(string, null)<br/>    stage               = optional(string, null)<br/>    name                = optional(string, null)<br/>    delimiter           = optional(string, null)<br/>    attributes          = optional(list(string), [])<br/>    tags                = optional(map(string), {})<br/>    label_order         = optional(list(string), null)<br/>    regex_replace_chars = optional(string, null)<br/>    id_length_limit     = optional(number, null)<br/>    label_key_case      = optional(string, null)<br/>    label_value_case    = optional(string, null)<br/>    labels_as_tags      = optional(set(string), null)<br/>    descriptor_formats = optional(map(object({<br/>      format = string<br/>      labels = list(string)<br/>    })), {})<br/>  })</pre> | `{}` | no |
| <a name="input_custom_rule_group_capacity"></a> [custom\_rule\_group\_capacity](#input\_custom\_rule\_group\_capacity) | WCU capacity for custom rule group. 0 to skip. | `number` | `0` | no |
| <a name="input_custom_rules"></a> [custom\_rules](#input\_custom\_rules) | Custom rules for the rule group. | `any` | `[]` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | Default action for the Web ACL. Valid values: allow, block. | `string` | `"allow"` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>   format = string<br/>   labels = list(string)<br/>}`<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | <pre>map(object({<br/>    format = string<br/>    labels = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT'. | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` to keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_ip_address_version"></a> [ip\_address\_version](#input\_ip\_address\_version) | IP address version. Valid values: IPV4, IPV6. | `string` | `"IPV4"` | no |
| <a name="input_ip_addresses"></a> [ip\_addresses](#input\_ip\_addresses) | List of IP addresses or CIDR blocks for the IP set. | `list(string)` | `[]` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>Note: The value of the `name` tag, if included, will be the `id`, not the `name`. | `set(string)` | `null` | no |
| <a name="input_logging_destination_arn"></a> [logging\_destination\_arn](#input\_logging\_destination\_arn) | ARN of the logging destination. Null to skip. | `string` | `null` | no |
| <a name="input_logging_redacted_fields"></a> [logging\_redacted\_fields](#input\_logging\_redacted\_fields) | Fields to redact from WAF logs. | `any` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique. | `string` | `null` | no |
| <a name="input_regex_patterns"></a> [regex\_patterns](#input\_regex\_patterns) | List of regex patterns. Empty list skips creation. | `list(string)` | `[]` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release'. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element. A customer identifier, indicating who this instance of a resource is for. | `string` | `null` | no |
| <a name="input_web_acl_rules"></a> [web\_acl\_rules](#input\_web\_acl\_rules) | List of WAF rules for the Web ACL. | `any` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_ip_set_arn"></a> [ip\_set\_arn](#output\_ip\_set\_arn) | The ARN of the IP set. |
| <a name="output_rule_group_arn"></a> [rule\_group\_arn](#output\_rule\_group\_arn) | The ARN of the custom rule group. |
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | The ARN of the Web ACL. |
| <a name="output_web_acl_id"></a> [web\_acl\_id](#output\_web\_acl\_id) | The ID of the Web ACL. Use this in aws\_cloudfront\_distribution.web\_acl\_id. |
<!-- END_TF_DOCS -->

## Tests

Native `terraform test` runs against a **mocked** AWS provider — no real resources are
created and no credentials are needed. Assertions target plan-known values (the `tf-label`
id string, module counts, and input pass-throughs) so they stay deterministic under mocking.

```bash
# Run the unit test suite
terraform init -backend=false
terraform test -test-directory=tests/unit -verbose

# Or via the Makefile
make test
```

| Suite | Path | Provider | What it checks |
|-------|------|----------|----------------|
| Unit | `tests/unit/main_test.tftest.hcl` | mocked | id composition, optional sub-module gating (regex/rule-group/logging), `enabled = false` disables the stack |
| Integration | `tests/integration/main_test.tftest.hcl` | real AWS (`us-east-1`) | opt-in, creates real WAF resources |

Integration tests are opt-in (they create billable AWS resources):

```bash
make test-integration   # terraform test -test-directory=tests/integration
```

## Learning Materials

| Document | Description |
|----------|-------------|
| [docs/TERRAFORM_FLAGS.md](docs/TERRAFORM_FLAGS.md) | Terraform CLI flags reference (`-refresh`, `-upgrade`, etc.) |
| [docs/TFENV.md](docs/TFENV.md) | tfenv version manager guide |
| [docs/MAKEFILE_ENV.md](docs/MAKEFILE_ENV.md) | Makefile targets and `.env` configuration |
| [TEMPLATE_GUIDE.md](TEMPLATE_GUIDE.md) | Step-by-step guide to customise this template |
| [WORKFLOW.md](WORKFLOW.md) | Branching strategy and CI/CD pipeline |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development workflow and guidelines |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow and guidelines.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## License

[MIT](LICENSE)
