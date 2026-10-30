---
name: terraform-generator
description: Write Terraform and Terragrunt code for AWS following the user's state, layout, IAM, and tagging conventions.
when_to_use: Creating or changing infrastructure code, modules, IAM policies, or tags, e.g. "테라폼 작성", "IAM 정책 추가", "모듈 개선", "terragrunt.hcl 추가", "리소스 정리". Plan and apply run only when the user asks. Not for NodePool, EC2NodeClass, or other Kubernetes YAML (use k8s-manifest) or Helm chart values (use helm-chart).
argument-hint: "[resource or module]"
license: Apache-2.0
compatibility: terraform or OpenTofu 1.10+, terragrunt 1.x when the repo uses it
metadata:
  version: "2.2.0"
  category: generator
  related: done-check git-ship k8s-manifest helm-chart
allowed-tools: Bash(terraform fmt *) Bash(terraform init -backend=false*) Bash(terraform validate*) Bash(tofu fmt *) Bash(tofu init -backend=false*) Bash(tofu validate*) Bash(terragrunt hcl fmt*) Bash(terragrunt hcl validate*) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Terraform

General practice (pinned providers, variable validation, encryption at rest, least privilege) applies without restating it. Comments follow the global Code Comments rule. Commands below say `terraform`, run `tofu` instead where only OpenTofu is installed.

## Layout And State

- Follow the repo's existing layout first; Terragrunt repos keep one `terragrunt.hcl` per environment and resource, shared pieces under the repo's common-resource directory
- `required_version >= 1.10.0`; S3 backend with `use_lockfile = true` and `encrypt = true`, no DynamoDB lock table
- Names: `${project}-${environment}-${resource}`, lowercase with hyphens

## IAM

- Each service owns its policies under its own directory; never attach another service's policy even when the permissions match, copy the needed statements instead
- `Sid` names the feature that needs the permission
- Policy `description` is a complete English sentence without `/` or parentheses (`Allows the merchant service to read its secrets.`, not `pay/merchant (secret)`)

## Tags

- Issue key and description tags on every resource that supports them, using the repo's tag key convention. An unknown issue key is asked for, never invented
- Tag values only use letters, digits, spaces, and `_ . : / = + - @`; no parentheses or commas (apply fails although plan passes)
- EC2 instances with instance metadata tags enabled cannot have `/` in tag keys; replace it with `:`
- `karpenter.sh/discovery` goes on subnet and security group tags only, never in module-wide `tags` that reach node launch templates

## EKS

- kube-proxy add-on `configuration_values` sets `mode` explicitly to `iptables` or `nftables`, never `ipvs` (deprecated) and never left to the default (flips to nftables upstream). nftables only when every node runs Linux 5.13+ and VPC CNI v1.23.0+, and after testing anything that reaches a NodePort through `localhost`
- Node AMIs are AL2023 or Bottlerocket (cgroup v2), never Amazon Linux 2
- Karpenter interruption queue comes from the `terraform-aws-modules/eks` `karpenter` submodule (`enable_spot_termination = true`: SQS queue, queue policy, EventBridge rules for Spot interruption, rebalance, state change, AWS Health, capacity reservation interruption). Its `queue_name` output feeds Karpenter `settings.interruptionQueue`. No Node Termination Handler resources alongside it (the only exception is defined in k8s-manifest)
- The v21 `karpenter` submodule authenticates through Pod Identity, so the cluster runs the `eks-pod-identity-agent` add-on

## Execution

- Plan, apply, and destroy run only on explicit request; otherwise hand the exact command to the user
- Removal work destroys first, then deletes the code, in that order

## Validation

- `terraform fmt -check -recursive`, plus `terragrunt hcl fmt --check` in Terragrunt repos (never `hclfmt`, removed in Terragrunt 0.90)
- `terraform init -backend=false` then `terraform validate` in each touched root module
- Terragrunt units use offline `terragrunt hcl validate`. Errors that an untouched sibling unit also reports come from `root.hcl` and are not new
- `terragrunt validate` inits the real backend, so it needs credentials and is not an offline check
