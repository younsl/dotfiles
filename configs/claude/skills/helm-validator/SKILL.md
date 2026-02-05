# Helm Chart Validator

Validate Helm charts for correctness, security, and best practices.

## When to Use
- Before publishing or deploying Helm charts
- Reviewing Helm chart changes
- CI/CD pipeline validation

## Core Rules

### 1. Run helm lint First

Use `helm lint --strict` to catch warnings as errors.

### 2. Render and Validate Templates

Use `helm template | kubeconform` to validate rendered output.

### 3. Check values.yaml Defaults

Verify secure defaults for `securityContext` and `resources`.

### 4. Verify Chart.yaml Metadata

Ensure `version`, `appVersion`, and `maintainers` are set.

### 5. Test with Different Values

Validate with both default and custom values files.

## Validation Process

### Step 1: Lint Check
```bash
helm lint <chart-path>
helm lint <chart-path> --strict  # Fail on warnings
```

### Step 2: Template Rendering
```bash
# Render templates to verify output
helm template <release-name> <chart-path> --debug

# With custom values
helm template <release-name> <chart-path> -f custom-values.yaml --debug
```

### Step 3: Kubernetes Validation
```bash
# Validate rendered manifests
helm template <release-name> <chart-path> | kubeconform -strict -summary
```

### Step 4: Dependency Check
```bash
# For charts with dependencies
helm dependency list <chart-path>
helm dependency update <chart-path>
```

## Validation Checklist

### Chart.yaml
```
[ ] apiVersion: v2 (Helm 3)
[ ] name matches directory name
[ ] version follows SemVer
[ ] appVersion set appropriately
[ ] description is meaningful
[ ] maintainers defined
```

### values.yaml
```
[ ] All values have sensible defaults
[ ] No hardcoded secrets
[ ] Image tag not set to 'latest'
[ ] Resource requests/limits defined
[ ] Security context configured
[ ] Comments explain non-obvious values
```

### Templates
```
[ ] _helpers.tpl includes standard helpers
[ ] All templates use include for labels
[ ] Proper indentation (use nindent)
[ ] No hardcoded namespaces
[ ] NOTES.txt provides useful info
```

### Security
```
[ ] podSecurityContext defined with secure defaults
[ ] securityContext defined per container
[ ] ServiceAccount created with minimal permissions
[ ] No privileged: true by default
[ ] Secrets handled properly (not in values.yaml)
```

### Best Practices
```
[ ] Supports nodeSelector, tolerations, affinity
[ ] HPA configurable
[ ] PDB configurable
[ ] Image pull secrets configurable
[ ] Resource names use fullname helper
```

## Common Issues and Fixes

### Missing Required Values
```yaml
# Use required function for mandatory values
image:
  repository: {{ required "image.repository is required" .Values.image.repository }}
```

### Incorrect Indentation
```yaml
# Bad
spec:
  containers:
  - name: {{ .Chart.Name }}
    env:
{{ toYaml .Values.env | indent 6 }}

# Good
spec:
  containers:
  - name: {{ .Chart.Name }}
    env:
      {{- toYaml .Values.env | nindent 6 }}
```

### Hardcoded Values
```yaml
# Bad
namespace: production

# Good
namespace: {{ .Release.Namespace }}
```

### Missing Quotes
```yaml
# Bad (fails if value is number)
name: {{ .Values.name }}

# Good
name: {{ .Values.name | quote }}
```

## Output Format
```
## Helm Chart Validation Results

### Chart Info
- Name: <chart-name>
- Version: <version>
- AppVersion: <app-version>

### Lint Results
- [ ] helm lint: PASSED/FAILED
- [ ] helm lint --strict: PASSED/FAILED

### Template Validation
- [ ] Templates render successfully
- [ ] Kubernetes schema valid

### Security Assessment
- [ ] Security context configured
- [ ] No hardcoded secrets
- [ ] ServiceAccount properly configured

### Recommendations
1. Add PodDisruptionBudget template
2. Consider adding HPA support
```
