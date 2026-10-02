---
name: promql-generator
description: Write and validate PromQL queries, PrometheusRule alerts, and Grafana dashboard panels against live data, following the user's alert copy and dashboard rules.
when_to_use: Writing alerts, recording rules, dashboard panels, or SLO queries, e.g. "알람 룰 추가", "80% 알람 걸어둬", "대시보드 패널 추가", "PromQL 작성", "알람 예외처리". 
argument-hint: "[metric or goal]"
license: Apache-2.0
compatibility: curl access to the Prometheus-compatible query API in $PROMETHEUS_URL; promtool optional
metadata:
  version: "2.0.0"
  category: generator
  related: helm-chart done-check
allowed-tools: Bash(curl *) Bash(promtool *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# PromQL, Alerts, Dashboards

PromQL fundamentals (rate over counters, RED and USE patterns, histogram quantiles, recording rules for heavy queries) apply without restating them. Comments in rule and dashboard files follow the global Code Comments rule.

## Live Verification

- Label values come from the live API, never from cloud tags or guesses: `curl -sG "$PROMETHEUS_URL/api/v1/label/<name>/values"` or `/api/v1/series`
- Every alert `expr` and panel query is executed with `curl -sG "$PROMETHEUS_URL/api/v1/query" --data-urlencode 'query=...'`; it must return the expected series with plausible values
- Ask for `$PROMETHEUS_URL` (and any tenant header) once if unset

## Alert Copy

- `summary`: short Korean sentence, no cluster name
- `description`: starts with `[{{ $externalLabels.cluster }}]`, states the symptom, then the high-level remediation direction; no separate action annotation
- Cluster identity from `$externalLabels.cluster`, not a metric `cluster` label
- No hardcoded thresholds or config values in remediation text
- Overlapping alerts: keep the broader one, remove the narrower
- `for` and `severity` set on every rule

## Grafana Panels

- Panel `description` in English
- `byRegexp` override matchers wrapped in slashes: `/limit/`
- One unit per axis; adaptive units only in tooltips
- Legend-based overrides over `byFrameRefID` after aggregation

## Collector Migration

Replacing an exporter or scraper ships in two MRs: parallel run under a temporary `job` label with baseline and diff queries in 테스트 결과, then cutover.

## Validation

- Live query returns data for every new expr and panel
- `promtool check rules` passes for rule files
