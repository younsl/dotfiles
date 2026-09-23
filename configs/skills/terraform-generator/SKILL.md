---
name: terraform-generator
description: Generate production-ready Terraform configurations. Use when creating infrastructure resources, Terraform modules, or AWS IaC definitions.
---

# Terraform Configuration Generator

Generate Terraform configurations following these conventions. General best practices (pinned providers, validation blocks, least-privilege IAM, encryption at rest) apply without restating them here.

## State Locking Convention

- `required_version >= 1.10.0`
- S3 backend with `use_lockfile = true` for native state locking — **no DynamoDB lock table**
- `encrypt = true`

```hcl
terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "example-tfstate"
    key          = "prd/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
```

## Naming Convention

- Pattern: `${project}-${environment}-${resource}`
- Lowercase with hyphens
- Environment included in resource names

## Project Structure

```
terraform/
├── environments/
│   ├── dev/
│   ├── stg/
│   └── prd/
└── modules/
    └── <module-name>/
```
