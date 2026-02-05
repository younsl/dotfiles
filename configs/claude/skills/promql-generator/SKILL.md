# PromQL Query Generator

Generate PromQL queries for Prometheus monitoring, alerting, and Grafana dashboards.

## When to Use
- Creating monitoring queries for dashboards
- Writing alerting rules
- Analyzing metrics and performance
- Building SLO/SLI queries

## Core Rules

### 1. Use rate() for Counters

Always use `rate()` or `increase()` with counter metrics.

### 2. Set Appropriate Time Range

Use `[5m]` minimum for `rate()` to handle scrape gaps.

### 3. Add Label Filters

Filter by job, namespace, or service to reduce cardinality.

### 4. Use Recording Rules

Create recording rules for expensive or frequently used queries.

### 5. Follow Naming Convention

Use `namespace_subsystem_name_unit` format for custom metrics.

## PromQL Fundamentals

### Selectors
```promql
# Exact match
http_requests_total{job="api-server", method="GET"}

# Regex match
http_requests_total{job=~"api-.*"}

# Negative match
http_requests_total{job!="test"}

# Regex negative match
http_requests_total{status!~"2.."}
```

### Common Functions

#### Rate and Increase
```promql
# Per-second rate over 5 minutes (for counters)
rate(http_requests_total[5m])

# Total increase over 1 hour
increase(http_requests_total[1h])

# Instant rate (last two samples)
irate(http_requests_total[5m])
```

#### Aggregation
```promql
# Sum by label
sum by (job) (rate(http_requests_total[5m]))

# Average by label
avg by (instance) (node_cpu_seconds_total)

# Count unique series
count(up{job="api"})

# Top 5 by value
topk(5, sum by (pod) (rate(container_cpu_usage_seconds_total[5m])))
```

## Common Metric Patterns

### RED Method (Request, Error, Duration)

#### Request Rate
```promql
# Requests per second
sum(rate(http_requests_total[5m]))

# Requests by endpoint
sum by (endpoint) (rate(http_requests_total[5m]))
```

#### Error Rate
```promql
# Error percentage
sum(rate(http_requests_total{status=~"5.."}[5m]))
/ sum(rate(http_requests_total[5m])) * 100

# Error rate by service
sum by (service) (rate(http_requests_total{status=~"5.."}[5m]))
/ sum by (service) (rate(http_requests_total[5m])) * 100
```

#### Duration (Latency)
```promql
# P50 latency
histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# P95 latency
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# P99 latency
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# Average latency
sum(rate(http_request_duration_seconds_sum[5m]))
/ sum(rate(http_request_duration_seconds_count[5m]))
```

### USE Method (Utilization, Saturation, Errors)

#### CPU
```promql
# CPU utilization by node
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# CPU utilization by pod
sum by (pod) (rate(container_cpu_usage_seconds_total[5m]))
/ sum by (pod) (container_spec_cpu_quota / container_spec_cpu_period) * 100
```

#### Memory
```promql
# Memory utilization by node
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Memory utilization by pod
sum by (pod) (container_memory_working_set_bytes)
/ sum by (pod) (container_spec_memory_limit_bytes) * 100
```

#### Disk
```promql
# Disk utilization
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

# Disk I/O
rate(node_disk_io_time_seconds_total[5m]) * 100
```

### Kubernetes Specific

#### Pod Status
```promql
# Pods not ready
sum by (namespace) (kube_pod_status_ready{condition="false"})

# Pods in CrashLoopBackOff
sum by (namespace, pod) (kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"})

# Pod restarts
sum by (namespace, pod) (increase(kube_pod_container_status_restarts_total[1h]))
```

#### Resource Requests vs Usage
```promql
# CPU request vs actual (over-provisioned if < 1)
sum by (namespace) (rate(container_cpu_usage_seconds_total[5m]))
/ sum by (namespace) (kube_pod_container_resource_requests{resource="cpu"})

# Memory request vs actual
sum by (namespace) (container_memory_working_set_bytes)
/ sum by (namespace) (kube_pod_container_resource_requests{resource="memory"})
```

## Alerting Rule Templates

### High Error Rate
```yaml
- alert: HighErrorRate
  expr: |
    sum(rate(http_requests_total{status=~"5.."}[5m]))
    / sum(rate(http_requests_total[5m])) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value | humanizePercentage }}"
```

### High Latency
```yaml
- alert: HighLatency
  expr: |
    histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m]))) > 1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High P95 latency"
    description: "P95 latency is {{ $value | humanizeDuration }}"
```

### Pod CrashLooping
```yaml
- alert: PodCrashLooping
  expr: |
    increase(kube_pod_container_status_restarts_total[1h]) > 5
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Pod {{ $labels.pod }} is crash looping"
```

## SLO/SLI Queries

### Availability SLI
```promql
# Success rate (availability)
sum(rate(http_requests_total{status!~"5.."}[30d]))
/ sum(rate(http_requests_total[30d]))
```

### Error Budget
```promql
# Remaining error budget (target 99.9%)
1 - (
  (1 - sum(rate(http_requests_total{status!~"5.."}[30d])) / sum(rate(http_requests_total[30d])))
  / (1 - 0.999)
)
```

## Validation
```bash
# Validate query syntax
promtool query instant http://prometheus:9090 'up{job="api"}'

# Check in Prometheus UI
# Navigate to /graph and test query
```
