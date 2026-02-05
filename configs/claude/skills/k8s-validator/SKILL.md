# Kubernetes Manifest Validator

Validate Kubernetes YAML manifests for correctness, security, and best practices.

## When to Use
- Before applying manifests to cluster
- Reviewing Kubernetes configurations
- CI/CD pipeline validation

## Core Rules

### 1. Validate YAML Syntax First

Run `yamllint` before schema validation.

### 2. Use kubeconform for Schema Check

Validate against Kubernetes API schema with `kubeconform -strict`.

### 3. Check Security Context

Verify `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation`.

### 4. Verify Resource Limits

Ensure all containers have CPU and memory requests/limits.

### 5. No latest Image Tags

Reject manifests using `latest` or missing image tags.

## Validation Process

### Step 1: YAML Syntax Check
```bash
yamllint -d relaxed <file.yaml>
```

### Step 2: Kubernetes Schema Validation
```bash
# Validate against K8s schema
kubeconform -strict -summary <file.yaml>

# For CRDs, add schema location
kubeconform -strict -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  <file.yaml>
```

### Step 3: Security & Best Practice Checks

#### Required Checks
1. **Resource Limits**: Every container must have requests and limits
2. **Security Context**: Must be defined at pod/container level
3. **Image Tags**: No `latest` tags in production
4. **Probes**: Liveness and readiness probes required for Deployments
5. **Labels**: Standard Kubernetes labels present

#### Security Checklist
```
[ ] securityContext.runAsNonRoot: true
[ ] securityContext.readOnlyRootFilesystem: true (if possible)
[ ] securityContext.allowPrivilegeEscalation: false
[ ] No privileged containers
[ ] No hostNetwork, hostPID, hostIPC unless justified
[ ] ServiceAccount with minimal permissions
[ ] No secrets in plain text (use Secret resources or external-secrets)
```

#### Production Readiness Checklist
```
[ ] replicas >= 2 for HA
[ ] PodDisruptionBudget defined
[ ] Anti-affinity rules for spreading pods
[ ] Resource requests = limits for guaranteed QoS (optional)
[ ] Appropriate update strategy defined
```

#### EKS Best Practices Checklist
```
[ ] dnsConfig.options.ndots set to 2 (reduces external DNS latency)
[ ] topologySpreadConstraints or podAntiAffinity for AZ spread
[ ] terminationGracePeriodSeconds appropriate for workload (default 30s)
[ ] preStop hook for graceful connection draining
[ ] startupProbe for slow-starting applications
[ ] Karpenter nodeSelector or nodeAffinity if using Karpenter
```

### Step 4: Dry Run
```bash
kubectl apply --dry-run=server -f <file.yaml>
```

## Common Issues and Fixes

### Missing Resources
```yaml
# Bad
containers:
- name: app
  image: myapp:v1

# Good
containers:
- name: app
  image: myapp:v1
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "512Mi"
```

### Insecure Security Context
```yaml
# Bad
securityContext: {}

# Good
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

### Missing Probes
```yaml
# Required for Deployments
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## Output Format
Report validation results as:
```
## Validation Results

### Passed
- [x] YAML syntax valid
- [x] Kubernetes schema valid

### Warnings
- [ ] Missing PodDisruptionBudget
- [ ] Single replica configured

### Errors
- [ ] Missing resource limits
- [ ] No security context defined

### Recommendations
1. Add resource limits to container 'app'
2. Set securityContext.runAsNonRoot: true
```
