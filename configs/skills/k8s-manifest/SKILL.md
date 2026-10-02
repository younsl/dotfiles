---
name: k8s-manifest
description: Author and review raw Kubernetes manifests and CRD resources (Karpenter, External Secrets, Gateway API, Kyverno) following EKS conventions and the user's field rules.
when_to_use: Writing or reviewing Deployments, NodePools, ExternalSecrets, HTTPRoutes, admission policies, or other YAML resources, e.g. "매니페스트 작성", "NodePool 추가", "ExternalSecret 생성", "ArgoCD diff 해소", "kyverno 정책 작성". Not for Helm template structure (use helm-chart).
argument-hint: "[manifest path or resource kind]"
license: Apache-2.0
compatibility: kubeconform; kubectl for server-side dry-run
metadata:
  version: "2.0.0"
  category: generator
  related: helm-chart done-check
allowed-tools: Bash(kubeconform *) Bash(kubectl apply --dry-run=server *) Bash(kubectl get *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Kubernetes Manifest

Standard production practice (pinned tags, non-root `securityContext`, probes, `app.kubernetes.io/*` labels, PDB, HA replicas) applies without restating it. Comments follow the global Code Comments rule. Below are the conventions that differ from defaults.

## Workloads

- Memory limit set, CPU limit omitted (CFS throttling); CPU request only
- Omit fields a controller owns: `spec.replicas` under HPA, KEDA, or Rollouts; resources under VPA. Otherwise add ArgoCD `ignoreDifferences`
- `nodeAffinity.matchExpressions` and Karpenter NodePool `requirements` order: `kubernetes.io/os`, `kubernetes.io/arch`, worker selector (node kind label, `karpenter.sh/nodepool`), then zone or others; a worker label requested for a NodePool goes in both `template.metadata.labels` and `requirements`
- Clusters mix amd64 and arm64 nodes; images must be multi-arch or the arch constraint explicit
- `resizePolicy` right after `resources`: cpu `NotRequired`, memory `RestartContainer`
- `preStop` sleep with matching `terminationGracePeriodSeconds`; `automountServiceAccountToken: false` unless the API is called; `dnsConfig.options.ndots: "2"` after testing

## CRDs With Server-Side Defaults

Write CRD default fields explicitly so ArgoCD does not show permanent drift.

| Resource | Fields to spell out |
|----------|---------------------|
| ExternalSecret `data[].remoteRef` | `conversionStrategy: Default`, `decodingStrategy: None`, `metadataPolicy: None` |
| ExternalSecret `target` | `creationPolicy: Owner`, `deletionPolicy: Retain` |
| Gateway API `parentRefs`, `backendRefs` | `group`, `kind`, `name`, `namespace` |

Verify by diffing `kubectl get <kind> <name> -o jsonpath='{.spec}'` against git.

## Karpenter

- NodePool with a single instance type limits by `limits.nodes`, not cpu or memory
- System and workload pools are separated by a node kind label plus matching taints

## Secrets And Policies

- Secret keys named by value type, consistent across siblings (`Amd64RunnerToken`, `Arm64RunnerToken`)
- Kyverno and admission policy `title`, `description`, and messages in English

## Operations

- Never use `kubectl port-forward` for verification; query in-cluster or read resources
- Never modify kubeconfig contexts; cluster-changing commands are handed to the user unless they asked Claude to apply

## Review Output

Errors, then warnings, one line each with `file:line` and the fix; then validation results.

## Validation

- `kubeconform -strict -summary` passes, with CRD schemas from the catalog
- `kubectl apply --dry-run=server` passes where cluster access exists
