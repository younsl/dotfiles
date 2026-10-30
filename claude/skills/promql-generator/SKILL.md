---
name: promql-generator
description: Write and validate PromQL queries, PrometheusRule alerts, and Grafana dashboard panels against live data, following the user's alert copy and dashboard rules.
when_to_use: Writing alerts, recording rules, dashboard panels, or SLO queries, e.g. "알람 룰 추가", "80% 알람 걸어둬", "대시보드 패널 추가", "PromQL 작성", "알람 예외처리". Not for chart templates such as prometheusrule.yaml (use helm-chart) or other Kubernetes manifests (use k8s-manifest).
argument-hint: "[metric or goal]"
license: Apache-2.0
compatibility: curl access to the Prometheus-compatible query API in $PROMETHEUS_URL; promtool, yq
metadata:
  version: "2.2.0"
  category: generator
  related: helm-chart k8s-manifest done-check
allowed-tools: Bash(curl *) Bash(promtool *) Bash(yq *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# PromQL, Alerts, Dashboards

## Live Verification

- Label names and values come from the live API, never from cloud tags, semconv defaults, or guesses: `curl -sG "$PROMETHEUS_URL/api/v1/label/<name>/values"` or `/api/v1/series`
- Every alert `expr` and panel query is executed with `curl -sG "$PROMETHEUS_URL/api/v1/query" --data-urlencode 'query=...'`; it must return the expected series with plausible values
- Ask for `$PROMETHEUS_URL` (and any tenant header) once if unset. Without it, ship rules marked unverified with the curl checks listed, and prove firing with `promtool test rules` on synthetic series

## Alert Selection

- Pages fire on symptoms users feel: p99 latency from `histogram_quantile` (never the average), 5xx ratio of total requests (never a raw error count), traffic drop against the same weekday last week (`offset 1w`) with the current side wrapped in `or vector(0)` so a vanished series fires, guarded by a minimum last-week rate. 4xx tracked separately
- Cause metrics (CPU, memory, pool usage) are warning-level and routed to a ticket queue, never pages. Saturation pages only when it predicts an outage, such as `predict_linear` disk fill within hours
- Pages are `severity: critical`, ticket-queue alerts `severity: warning`. No extra routing label
- A request to page on a cause metric ("CPU 80% 알람") is written as warning and the response says it is not a page
- Components with no request path (batch jobs, controllers) page on their own outcome: job failure, reconcile errors, or staleness of the last successful run
- Container CPU is read with the CFS throttled ratio `rate(container_cpu_cfs_throttled_periods_total[5m]) / rate(container_cpu_cfs_periods_total[5m])`, not average usage

## Alert Copy

- `summary`: short Korean sentence, no cluster name. English for public OSS chart examples
- `description`: starts with `[{{ $externalLabels.cluster }}]`, states the symptom, then the high-level remediation direction; no separate action annotation
- Cluster identity from `$externalLabels.cluster`, not a metric `cluster` label
- No hardcoded thresholds or config values in remediation text
- Overlapping alerts are found in loaded rules (`curl -s "$PROMETHEUS_URL/api/v1/rules"`) and repo rule files, not `ALERTS`, which only holds pending and firing ones. Keep the broader one, remove the narrower
- `for` and `severity` set on every rule

## Grafana Panels

- Panel `description` in English
- `byRegexp` override matchers wrapped in slashes: `/limit/`
- One unit per axis; adaptive units only in tooltips
- Legend-based overrides over `byFrameRefID` after aggregation

## Collector Migration

Replacing an exporter or scraper ships in two MRs: parallel run under a temporary `job` label with baseline and diff queries in 테스트 결과, then cutover.

## Validation

- `promtool check rules --lint=all` passes on the rule groups (`yq '.spec'` for PrometheusRule CRs)
- Each new alert has a live query result, or a passing `promtool test rules` case and an unverified note in the response
