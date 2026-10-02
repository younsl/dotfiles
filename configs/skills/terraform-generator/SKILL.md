---
name: terraform-generator
description: Write Terraform and Terragrunt code for AWS following the user's state, layout, IAM, and tagging conventions.
when_to_use: Creating or changing infrastructure code, modules, IAM policies, or tags, e.g. "테라폼 작성", "IAM 정책 추가", "모듈 개선", "terragrunt.hcl 추가", "리소스 정리". Plan and apply run only when the user asks.
argument-hint: "[resource or module]"
license: Apache-2.0
compatibility: terraform 1.10+, terragrunt when the repo uses it
metadata:
  version: "2.0.0"
  category: generator
  related: done-check git-ship
allowed-tools: Bash(terraform fmt *) Bash(terraform validate*) Bash(terragrunt hclfmt*) Bash(terragrunt validate*) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Terraform

General practice (pinned providers, variable validation, encryption at rest, least privilege) applies without restating it. Comments follow the global Code Comments rule.

## Layout And State

- Follow the repo's existing layout first; Terragrunt repos keep one `terragrunt.hcl` per environment and resource, shared pieces under the repo's common-resource directory
- `required_version >= 1.10.0`; S3 backend with `use_lockfile = true` and `encrypt = true`, no DynamoDB lock table
- Names: `${project}-${environment}-${resource}`, lowercase with hyphens

## IAM

- Each service owns its policies under its own directory; never attach another service's policy even when the permissions match, copy the needed statements instead
- `Sid` names the feature that needs the permission
- Policy `description` is a complete English sentence without `/` or parentheses (`pay merchant secret`, not `pay/merchant`)

## Tags

- Issue key and description tags on every resource that supports them, using the repo's tag key convention
- Tag values only use letters, digits, spaces, and `_ . : / = + - @`; no parentheses or commas (apply fails although plan passes)
- EC2 instances with instance metadata tags enabled cannot have `/` in tag keys; replace it with `:`

## Execution

- Plan, apply, and destroy run only on explicit request; otherwise hand the exact command to the user
- Removal work destroys first, then deletes the code, in that order

## Validation

- `terraform fmt -check -recursive` or `terragrunt hclfmt --check`
- `terraform validate` or `terragrunt validate` in each touched directory
