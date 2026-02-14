---
name: helm-validator
description: Validate Helm charts for correctness, security, and best practices. Use when reviewing or auditing Helm chart changes.
---

# Helm Chart Validator

Validate Helm charts for correctness, security, and best practices.

## Validation Criteria

### Chart.yaml

- `apiVersion: v2` (Helm 3)
- `name` matches directory name
- `version` follows SemVer
- `appVersion` set appropriately
- `description` is meaningful
- `maintainers` defined

### values.yaml

- All values have sensible defaults
- No hardcoded secrets
- Image tag not set to `latest`
- Resource requests/limits defined
- Security context configured
- Comments explain non-obvious values

### Templates

- `_helpers.tpl` includes standard helpers (name, fullname, labels, selectorLabels, serviceAccountName)
- All templates use `include` for labels
- Proper indentation with `nindent`
- No hardcoded namespaces
- `NOTES.txt` provides useful post-install info

### Security

- `podSecurityContext` defined with secure defaults
- `securityContext` defined per container
- ServiceAccount created with minimal permissions
- No `privileged: true` by default
- Secrets not stored in values.yaml

### Production Readiness

- `nodeSelector`, `tolerations`, `affinity` supported
- HPA configurable
- PDB configurable
- Image pull secrets configurable
- Resource names use fullname helper

## Common Issues

| Issue | Bad | Good |
|-------|-----|------|
| Indentation | `{{ toYaml .Values.env \| indent 6 }}` | `{{- toYaml .Values.env \| nindent 6 }}` |
| Hardcoded namespace | `namespace: production` | `namespace: {{ .Release.Namespace }}` |
| Missing quotes | `name: {{ .Values.name }}` | `name: {{ .Values.name \| quote }}` |
| Missing required | `image: {{ .Values.image }}` | `image: {{ required "image required" .Values.image }}` |

## Validation Commands

```bash
helm lint <chart-path> --strict
helm template <name> <chart-path> --debug
helm template <name> <chart-path> | kubeconform -strict -summary
helm dependency list <chart-path>
```

## Output Format

```
## Helm Chart Validation Results

### Chart Info
- Name: <chart-name>
- Version: <version>
- AppVersion: <app-version>

### Results
- [ ] helm lint: PASSED/FAILED
- [ ] Template rendering: PASSED/FAILED
- [ ] Kubernetes schema: PASSED/FAILED
- [ ] Security assessment: PASSED/FAILED

### Recommendations
1. ...
```
