---
name: helm-generator
description: Generate production-ready Helm charts. Use when creating new Helm charts, Chart.yaml, values.yaml, or Helm templates.
---

# Helm Chart Generator

Generate production-ready Helm charts following best practices.

## Output Requirements

- `apiVersion: v2` in Chart.yaml (Helm 3)
- String values quoted with `{{ .Values.foo | quote }}`
- Reusable labels and names defined in `_helpers.tpl`
- `securityContext` and `resources` with secure defaults in values.yaml
- `nodeSelector`, `tolerations`, `affinity` configurable
- Image registry configurable for air-gapped environments
- HPA and PDB available as optional features

## Chart Structure

```
<chart-name>/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   ├── configmap.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   └── NOTES.txt
└── README.md (optional)
```

## Security Defaults (values.yaml)

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
```

## Templating Constraints

- `{{ include }}` not `{{ template }}` for composability
- `default` for fallback values
- `required` for mandatory values
- `nindent` not `indent` for consistent indentation
- No hardcoded namespaces (use `{{ .Release.Namespace }}`)
- No secrets in values.yaml

## HPA-Aware Deployments

When `autoscaling.enabled` is true, omit `replicas` from Deployment to avoid GitOps conflicts:

```yaml
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
```

## Wrapper Charts

Include `dependencies` in Chart.yaml. For fields managed by external controllers, configure ArgoCD `ignoreDifferences`:

```yaml
spec:
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas
```

## Validation

- `helm lint --strict`
- `helm template <name> <path> | kubeconform -strict`
