---
name: k8s-generator
description: Generate production-ready Kubernetes manifests. Use when creating Deployments, Services, ConfigMaps, CRDs, or other Kubernetes YAML resources.
---

# Kubernetes Manifest Generator

Standard production practices (pinned image tags, non-root `securityContext` at pod and container level, probes, `app.kubernetes.io/*` labels, PDB, HA replica counts) apply without restating them here. Below are the conventions that differ from the defaults.

## Resource Policy — no CPU limits

Memory limits set; **CPU limits omitted**. CPU limits cause CFS throttling during burst traffic, producing latency spikes. The CPU request alone guarantees scheduling while allowing burst utilization.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    memory: "512Mi"
```

## Controller-Managed Fields

Omit fields from manifests when a controller owns them, to avoid GitOps drift:

| Field | Omit when managed by |
|-------|---------------------|
| `spec.replicas` | HPA, KEDA, Rollout controller |
| `resources.requests/limits` | VPA |
| `metadata.annotations` | External controllers (cert-manager) |

If the field must exist but is externally managed, configure ArgoCD `ignoreDifferences`.

## EKS Conventions

- `dnsConfig.options.ndots: "2"` to cut external DNS latency (test before applying)
- `topologySpreadConstraints` or `podAntiAffinity` for AZ distribution
- `preStop` hook with `sleep` for connection draining, `terminationGracePeriodSeconds` sized to match
- Karpenter `nodeSelector` when targeting Karpenter node pools
- `automountServiceAccountToken: false` unless the workload calls the API server
