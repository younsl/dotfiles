---
name: k8s-generator
description: Generate production-ready Kubernetes manifests. Use when creating Deployments, Services, ConfigMaps, CRDs, or other Kubernetes YAML resources.
---

# Kubernetes Manifest Generator

Generate production-ready Kubernetes YAML manifests.

## Output Requirements

- Image versions pinned (never `latest`)
- Resource requests defined for all containers
- Memory limits set; CPU limits omitted (prevents CFS throttling)
- `securityContext` set at both pod and container level
- Liveness and readiness probes defined for Deployments
- Standard `app.kubernetes.io/*` labels on all resources
- Multiple resources separated by `---`
- Resource ordering: Namespace > ServiceAccount > ConfigMap/Secret > Deployment/StatefulSet > Service > Ingress

## Resource Policy

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    memory: "512Mi"
    # CPU limit intentionally omitted to avoid CFS throttling
```

CPU limits cause CFS throttling during burst traffic, resulting in latency spikes. CPU request alone guarantees scheduling while allowing burst utilization.

## Security Constraints

- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true` when possible
- `allowPrivilegeEscalation: false`
- `seccompProfile.type: RuntimeDefault`
- No `privileged: true` without explicit justification
- `automountServiceAccountToken: false` unless needed
- No secrets in plain text (use Secret resources or external-secrets)

## Required Labels

```yaml
metadata:
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/instance: <instance>
    app.kubernetes.io/version: <version>
    app.kubernetes.io/component: <component>
    app.kubernetes.io/managed-by: <tool>
```

## Production Readiness

- `replicas >= 2` for HA
- PodDisruptionBudget defined
- RollingUpdate strategy with `maxUnavailable` and `maxSurge`

## EKS Best Practices

- `dnsConfig.options.ndots: "2"` to reduce external DNS latency (test before applying)
- `topologySpreadConstraints` or `podAntiAffinity` for AZ distribution
- `terminationGracePeriodSeconds` appropriate for workload
- `preStop` hook with `sleep` for connection draining
- `startupProbe` for slow-starting applications
- Karpenter `nodeSelector` if using Karpenter node pools

## Controller-Managed Fields

Omit fields from manifests when managed by controllers to avoid GitOps conflicts:

| Field | Omit When Managed By |
|-------|---------------------|
| `spec.replicas` | HPA, KEDA, Rollout controller |
| `resources.requests/limits` | VPA |
| `metadata.annotations` | External controllers (cert-manager) |

Configure ArgoCD `ignoreDifferences` if field must exist but is externally managed.
