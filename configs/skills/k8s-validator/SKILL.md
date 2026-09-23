---
name: k8s-validator
description: Validate Kubernetes YAML manifests for correctness, security, and best practices. Use when reviewing or auditing Kubernetes configurations.
---

# Kubernetes Manifest Validator

Validate Kubernetes YAML manifests for correctness, security, and best practices.

## Validation Criteria

### Schema & Syntax

- Valid YAML syntax
- Valid Kubernetes API schema (`kubeconform -strict`)
- CRDs validated against external schema catalogs

### Security

- `securityContext.runAsNonRoot: true`
- `securityContext.readOnlyRootFilesystem: true` (when possible)
- `securityContext.allowPrivilegeEscalation: false`
- No privileged containers
- No `hostNetwork`, `hostPID`, `hostIPC` unless justified
- ServiceAccount with minimal permissions
- No secrets in plain text

### Resource Management

- All containers have resource requests defined
- Memory limits set
- CPU limits omitted to avoid CFS throttling (justified if present)
- Image tags pinned (no `latest`)

### Reliability

- Liveness and readiness probes defined for Deployments
- `replicas >= 2` for HA
- PodDisruptionBudget defined
- Appropriate update strategy

### EKS Best Practices

- `dnsConfig.options.ndots` set to `2`
- `topologySpreadConstraints` or `podAntiAffinity` for AZ spread
- `terminationGracePeriodSeconds` appropriate for workload
- `preStop` hook for graceful connection draining
- `startupProbe` for slow-starting applications

### Labels & Metadata

- Standard `app.kubernetes.io/*` labels present
- No hardcoded namespaces in templates

## Validation Commands

```bash
yamllint -d relaxed <file.yaml>
kubeconform -strict -summary <file.yaml>
kubectl apply --dry-run=server -f <file.yaml>
```

## Output Format

```
## Validation Results

### Passed
- [x] Item

### Warnings
- [ ] Item

### Errors
- [ ] Item

### Recommendations
1. ...
```
