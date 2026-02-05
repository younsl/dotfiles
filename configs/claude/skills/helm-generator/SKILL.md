# Helm Chart Generator

Generate production-ready Helm charts following best practices.

## When to Use
- Creating new Helm charts from scratch
- Wrapping external Helm charts
- Converting Kubernetes manifests to Helm charts

## Core Rules

### 1. Use Helm 3 API Version

Set `apiVersion: v2` in Chart.yaml.

### 2. Quote String Values

Always use `{{ .Values.foo | quote }}` for string values.

### 3. Use Helper Templates

Define reusable templates in `_helpers.tpl` for labels and names.

### 4. Set Secure Defaults

Include `securityContext` and `resources` with safe defaults in values.yaml.

### 5. Support Customization

Allow `nodeSelector`, `tolerations`, `affinity` configuration.

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

## Chart.yaml Template

```yaml
apiVersion: v2
name: <chart-name>
description: <description>
type: application
version: 0.1.0
appVersion: "1.0.0"
maintainers:
  - name: <team-name>
    email: <team-email>
keywords:
  - <keyword1>
  - <keyword2>
```

### For Wrapper Charts (External Dependencies)
```yaml
apiVersion: v2
name: <chart-name>
description: Wrapper chart for <external-chart>
type: application
version: 0.1.0
appVersion: "1.0.0"

dependencies:
  - name: <external-chart>
    version: <version>
    repository: <helm-repo-url>

# helm repo add <repo-name> <repo-url>
# helm search repo <repo-name>/<chart-name> --versions
# helm show values <repo-name>/<chart-name> --version <version>
# helm dependency update
```

## values.yaml Template

```yaml
# Default values for <chart-name>

replicaCount: 2

image:
  repository: <image-repo>
  tag: ""  # Defaults to appVersion
  pullPolicy: IfNotPresent

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}
podLabels: {}

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

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

livenessProbe:
  httpGet:
    path: /healthz
    port: http
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

nodeSelector: {}
tolerations: []
affinity: {}

# Pod Disruption Budget
pdb:
  enabled: true
  minAvailable: 1
```

## _helpers.tpl Template

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "<chart-name>.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "<chart-name>.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "<chart-name>.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "<chart-name>.labels" -}}
helm.sh/chart: {{ include "<chart-name>.chart" . }}
{{ include "<chart-name>.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "<chart-name>.selectorLabels" -}}
app.kubernetes.io/name: {{ include "<chart-name>.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "<chart-name>.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "<chart-name>.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
```

## Best Practices

### Templating
- Use `{{ include }}` for reusable templates
- Always quote string values: `{{ .Values.foo | quote }}`
- Use `default` for fallback values
- Use `required` for mandatory values

### Security
- Never hardcode secrets in values.yaml
- Use `podSecurityContext` and `securityContext` by default
- Set restrictive defaults, allow override

### Flexibility
- Make image registry configurable for air-gapped environments
- Support nodeSelector, tolerations, affinity
- Include HPA and PDB as optional features

## Validation After Generation
```bash
helm lint <chart-path>
helm template <release-name> <chart-path> --debug
helm template <release-name> <chart-path> | kubeconform -strict
```
