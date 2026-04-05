---
name: promql-generator
description: Generate PromQL queries for Prometheus monitoring, alerting rules, and Grafana dashboards. Use when writing metrics queries, SLO/SLI definitions, or recording rules.
---

# PromQL Query Generator

Generate PromQL queries for Prometheus monitoring, alerting, and Grafana dashboards.

## Output Requirements

- Counter metrics wrapped in `rate()` or `increase()`
- `rate()` range minimum `[5m]` to handle scrape gaps
- Label filters applied (job, namespace, service) to reduce cardinality
- Expensive or frequently used queries extracted as recording rules
- Custom metric names follow `namespace_subsystem_name_unit` convention
- Alerting rules include `for` duration, `severity` label, and `summary`/`description` annotations

## Selector Syntax

| Operator | Example | Meaning |
|----------|---------|---------|
| `=` | `{job="api"}` | Exact match |
| `!=` | `{job!="test"}` | Not equal |
| `=~` | `{job=~"api-.*"}` | Regex match |
| `!~` | `{status!~"2.."}` | Regex not match |

## Query Patterns

### RED Method (Request, Error, Duration)

| Metric | Pattern |
|--------|---------|
| Request rate | `sum by (service) (rate(http_requests_total[5m]))` |
| Error rate % | `sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100` |
| P50 latency | `histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))` |
| P95 latency | `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))` |
| P99 latency | `histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))` |
| Avg latency | `sum(rate(http_request_duration_seconds_sum[5m])) / sum(rate(http_request_duration_seconds_count[5m]))` |

### USE Method (Utilization, Saturation, Errors)

| Metric | Pattern |
|--------|---------|
| CPU by node | `100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| Memory by node | `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100` |
| Disk utilization | `(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100` |

### Kubernetes

| Metric | Pattern |
|--------|---------|
| Pods not ready | `sum by (namespace) (kube_pod_status_ready{condition="false"})` |
| CrashLoopBackOff | `sum by (namespace, pod) (kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"})` |
| Pod restarts/hr | `sum by (namespace, pod) (increase(kube_pod_container_status_restarts_total[1h]))` |
| CPU req vs actual | `sum by (namespace) (rate(container_cpu_usage_seconds_total[5m])) / sum by (namespace) (kube_pod_container_resource_requests{resource="cpu"})` |

## Alerting Rule Structure

```yaml
- alert: <AlertName>
  expr: |
    <promql_expression>
  for: 5m
  labels:
    severity: critical|warning|info
  annotations:
    summary: "<human-readable summary>"
    description: "<detail with {{ $value }} or {{ $labels.xxx }}>"
```

## SLO/SLI Patterns

| Metric | Pattern |
|--------|---------|
| Availability SLI | `sum(rate(http_requests_total{status!~"5.."}[30d])) / sum(rate(http_requests_total[30d]))` |
| Error budget (99.9%) | `1 - ((1 - <availability_sli>) / (1 - 0.999))` |
