---
name: terraform-generator
description: Generate production-ready Terraform configurations. Use when creating infrastructure resources, Terraform modules, or AWS IaC definitions.
---

# Terraform Configuration Generator

Generate production-ready Terraform configurations following best practices.

## Output Requirements

- `required_version >= 1.10.0`
- Provider versions pinned with constraints (e.g., `~> 5.0`)
- S3 backend with `use_lockfile = true` for native state locking (no DynamoDB)
- State encryption enabled (`encrypt = true`)
- Input variables include `validation` blocks
- Sensitive outputs marked with `sensitive = true`
- No hardcoded secrets (use SSM Parameter Store or Secrets Manager)
- Encryption at rest enabled for S3, EBS, RDS resources

## Project Structure

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── stg/
│   └── prd/
└── modules/
    └── <module-name>/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Naming Convention

- Pattern: `${project}-${environment}-${resource}`
- Lowercase with hyphens
- Environment included in resource names

## Provider Configuration

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
    }
  }
}
```

## Variable Constraints

- Environment variables validated against allowed values
- CIDR blocks validated with `can(cidrhost(...))`
- All variables have `description`
- Optional variables have `default`

## Security Constraints

- S3 buckets: versioning enabled, public access blocked, server-side encryption
- IAM policies follow least privilege
- Logging enabled for auditable resources

## Module Design

- Modules accept `tags` variable of type `map(string)` with empty default
- Resources use `merge(var.tags, { Name = "..." })` for tag composition
- Module outputs include resource IDs and ARNs

## Validation

```bash
terraform fmt -recursive
terraform validate
tflint --recursive
checkov -d .
```
