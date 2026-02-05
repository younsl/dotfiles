# Kubernetes Manifest Generator

Generate production-ready Kubernetes YAML manifests following best practices.

## When to Use
- Creating new Kubernetes resources (Deployment, Service, ConfigMap, etc.)
- Converting application requirements to K8s manifests
- Generating CRD instances (Karpenter NodePool, Kyverno Policy, etc.)

## Core Rules

### 1. Pin Image Version

Never use `latest` tag. Always pin specific version (e.g., `nginx:1.25.3`).

### 2. Set Resource Requests and Limits

Every container must have resource requests. Set memory limits but avoid CPU limits (causes throttling).

#### Bad Case - With CPU Limit
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "100m"      # CPU limit set - causes throttling
        memory: "128Mi"
```
- CPU limit causes CFS throttling during burst traffic
- Results in latency spikes and response delays

#### Good Case - Without CPU Limit
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: "100m"      # Request only for scheduling guarantee
        memory: "128Mi"
      limits:
        memory: "128Mi"  # Memory limit retained (OOM protection)
        # CPU limit intentionally omitted
```
- CPU request guarantees minimum resources
- Can utilize idle CPU during burst
- Stable latency without throttling

### 3. Run as Non-Root

Set `securityContext.runAsNonRoot: true` and `allowPrivilegeEscalation: false`.

### 4. Define Probes

Add liveness and readiness probes for all Deployments.

### 5. Use Standard Labels

Include `app.kubernetes.io/*` labels for all resources.

## Generation Guidelines

### Required Fields
Always include these fields for production readiness:

```yaml
metadata:
  name: <resource-name>
  namespace: <namespace>
  labels:
    app.kubernetes.io/name: <app-name>
    app.kubernetes.io/instance: <instance>
    app.kubernetes.io/version: <version>
    app.kubernetes.io/component: <component>
    app.kubernetes.io/managed-by: <tool>
```

### Deployment Best Practices
```yaml
spec:
  replicas: 2  # Minimum for HA
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - name: <container-name>
        image: <image>:<tag>  # Always use specific tag, never 'latest'
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            memory: "512Mi"  # No CPU limit to avoid throttling
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        securityContext:
          runAsNonRoot: true
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
```

### Security Requirements
- Always set `securityContext` at pod and container level
- Use `readOnlyRootFilesystem: true` when possible
- Set `runAsNonRoot: true` unless absolutely necessary
- Never use `privileged: true` without justification
- Always specify resource requests and memory limits (avoid CPU limits)

### Pod Disruption Budget
For production workloads, always create PDB:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: <app>-pdb
spec:
  minAvailable: 1  # or maxUnavailable: 1
  selector:
    matchLabels:
      app: <app>
```

## EKS Best Practices

### DNS Optimization (ndots)
Default ndots (5) causes unnecessary CoreDNS queries for external domains. Set `ndots: 2` to reduce DNS lookup latency for external services (S3, RDS, etc.).

```yaml
spec:
  dnsConfig:
    options:
    - name: ndots
      value: "2"
    - name: edns0
```

**Warning**: Test thoroughly. Setting ndots too low may cause DNS lookup failures. Alternative: use trailing dot for external domains (e.g., `api.example.com.`).

### Topology Spread Constraints
Spread pods across AZs and nodes for high availability:
```yaml
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: <app-name>
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app: <app-name>
```

Use `DoNotSchedule` only if it's preferable for pods to not run instead of violating the constraint.

### Pod Anti-Affinity
Alternative to topology spread for distributing replicas:
```yaml
spec:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - <app-name>
          topologyKey: topology.kubernetes.io/zone
```

### Graceful Shutdown
Default grace period is 30 seconds. Increase for long-running requests and add preStop hook for connection draining:
```yaml
spec:
  terminationGracePeriodSeconds: 60
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 15"]
```

### Startup Probe
For slow-starting applications (e.g., Java apps hydrating caches):
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 2
```

### Node Selection for Karpenter
Use nodeSelector or affinity for Karpenter NodePools:
```yaml
spec:
  nodeSelector:
    karpenter.sh/nodepool: default
```

### Service Account
Create dedicated ServiceAccount for each application:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: <app>-sa
automountServiceAccountToken: false  # Set true only if needed
```

## Output Format
- Use `---` to separate multiple resources
- Order: Namespace > ServiceAccount > ConfigMap/Secret > Deployment/StatefulSet > Service > Ingress
- Add comments for non-obvious configurations

## Validation Checklist
After generation, verify:
- [ ] All required labels present
- [ ] Resource requests/limits defined
- [ ] Probes configured
- [ ] Security context set
- [ ] No hardcoded secrets (use Secret or external-secrets)
