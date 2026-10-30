---
name: api-timeout-investigation
description: Investigate API timeout incidents reported by external callers across CDN, API gateway, load balancer, mesh, application, and database layers, then publish a quantitative incident report with charts.
when_to_use: Requests such as "외부 요청 API Timeout 인시던트 조사", "API 호출 타임아웃 조사", "응답 지연 원인 분석", "000 응답 분석", "게이트웨이 지연인지 확인", "지연시간 분석 보고서", or a caller reporting timeouts against a domain or endpoint. Not for writing alert rules or dashboards (use promql-generator) or for prose rules alone (use writing-style).
argument-hint: "<url or endpoint> [time window]"
license: Apache-2.0
compatibility: aws CLI (cloudfront, apigatewayv2, elbv2, s3, cloudwatch, pi, rds), kubectl, curl, jq, python3 with matplotlib; Mimir query API in $MIMIR_URL, Loki and Tempo reached by kubectl port-forward on the observability cluster
metadata:
  version: "1.0.0"
  category: analyzer
  related: promql-generator writing-style done-check
allowed-tools: Bash(aws *) Bash(kubectl *) Bash(curl *) Bash(jq *) Bash(dig *) Bash(gzcat *) Bash(awk *) Bash(python3 *) Bash(git *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# External API Timeout Incident Investigation

When an external caller reports timeouts against our endpoint, answer "where does the time go" with per-layer numbers from logs and metrics, not from the caller's description.

## Site Values

| Variable | Meaning |
|----------|---------|
| `$MIMIR_URL` | Mimir base URL; queries go to `$MIMIR_URL/prometheus/api/v1/*` |
| `$OBS_KUBE_CONTEXT` | kubectl context of the cluster running Loki and Tempo |
| `$LOKI_TENANT` | `X-Scope-OrgID` for Loki and Tempo (read from the log shipper config when unset) |
| `$LOG_AWS_PROFILE` | AWS profile allowed to read CDN and LB access log buckets when the workload profile is denied |

## Output Requirements

- Request path is mapped hop by hop from DNS before any analysis: CDN distribution, origin and its read timeout, API gateway type and integration timeout, load balancer and target group, mesh gateway, route to the workload, and the datastores on the code path. Each hop records its own timeout
- Every layer gets the same statistics for the same window: count, p50, p90, p99, max, and count over the caller's timeout. Layers without a log are reported as not measured, never inferred
- Client disconnects are separated from server errors: CDN status `000` with `ClientCommError`, or LB `460`, is the caller giving up. The caller timeout is derived from the clustering of time-taken on those rows, per client IP and User-Agent
- The slow population is shown to be the same events across layers: per-bucket counts of client disconnects, LB processing time over the caller timeout, and application slow requests must match before the cause is named
- Scope check before blaming shared infrastructure: other endpoints on the same LB, same pods, and same time window are compared. Slowness confined to one endpoint rules out CDN, gateway, LB, node, and JVM-wide pauses
- Root cause is proven at the lowest layer reached with a time-aligned signal (database load by SQL at 1-second resolution, connection pool leak warnings, downstream logs), and the responsible code path is cited from the deployed commit (image tag), not the default branch
- Hypotheses not confirmed by data are labeled as estimates with the check that would confirm them
- Secrets never leave the terminal: bearer tokens, cookies, and customer identifiers in logs are dropped before writing files or reports

## Report Requirements

- Quantitative first: every claim carries a number, and every section with time or distribution data has a chart. Text explains the chart, it does not replace it
- Required charts: measurement architecture diagram (see Measurement Architecture), time series of the slow population across layers (client disconnects, LB processing time over threshold, app slow requests, pool leak warnings, database load), latency distribution on a log axis with the caller timeout lines, client disconnect time-taken histogram per client, per-layer percentile comparison, and a zoom of one burst at 1-second resolution
- Charts are PNG at 2x, one message per chart, Korean labels in the internal report, KST on every time axis
- All times in the report are KST with date and minute; raw UTC from logs is converted, and the window states both edges
- Structure follows the parent page siblings: 진행배경, TLDR, 측정 구간 아키텍처, 요약 정보, per-layer findings, 원인, 영향 평가, 권장 조치 (owner per action), 분석 한계
- Writing follows the writing-style skill; Confluence pages are created in storage format with charts attached
- Confluence pages open with the native table of contents macro (`<ac:structured-macro ac:name="toc"/>`) as the first element, before 진행배경
- Chart attachments are uploaded right after page creation and the page is confirmed to render them before the link is shared

## Measurement Architecture

The 측정 구간 아키텍처 section is one diagram plus a short bullet list, placed before any numbers so every later chart maps to a hop.

- Content: every hop from caller to datastore as one node in request order, each with name, one identifier (distribution ID, LB name, workload), and its timeout above the node. The caller is a node too, carrying its derived timeout
- Measurement taps: a dashed line from each hop that has a log or metric to the source name below it (CDN log, LB log, mesh metric, app log, database insights). Hops with no tap are visibly untapped and listed as not measured
- Verdict brackets under the nodes: one green bracket over the hops proven normal, one red bracket over the hops where the time goes, each with a single quantified label
- Bullets under the diagram define the measured span (what start and end each log records) and what no log covers, such as client to edge network time
- Style is minimal black, in the manner of Vercel dark diagrams: pure black canvas, near-black rounded nodes with a thin dark gray border, white bold node titles, muted gray monospace for identifiers and timeouts, thin gray connectors without arrowheads, and color only for status dots and brackets (green normal, red delay, amber caller-side). No gradients, shadows, icons, or fills beyond the node color
- Node text stays short enough to read at display width 760: one title, one identifier, no sentences inside nodes

## Reference

| Signal | Source | Note |
|--------|--------|------|
| CDN time-taken, status, edge result | CloudFront standard log in S3 | Fields: 8 uri, 9 status, 14 edge result, 19 time-taken, 29 detailed result. Time is UTC |
| LB target processing time | ALB access log in S3 | Field 7; `-1` means no response. Field 2 is response time in UTC |
| Gateway and mesh latency | Mimir `istio_request_duration_milliseconds_bucket` | Only `reporter="source"` exists when the workload has no sidecar |
| Container resources | Mimir cAdvisor and kube-state-metrics | CPU throttling only exists when a CPU limit is set |
| Application request duration | Loki access log JSON (`uri`, `duration`, `HOSTNAME`) | Query per hour to stay under the line limit |
| Pool saturation | Loki `ProxyLeakTask` and `Connection is not available` | Leak warning means the connection was held past the threshold, the stack shows where it was acquired |
| Spans | Tempo `/api/search` with TraceQL | Check sampling before relying on it; empty results for business routes mean dropped, not fast |
| Database | CloudWatch `AWS/RDS` per instance, Performance Insights `db.load.avg` grouped by `db.sql_tokenized` and `db.wait_event` | PI accepts 1-second periods for load; counter metrics return only at 60 seconds |

| Pattern | Reading |
|---------|---------|
| `000` time-taken packed at one value per client | Client timeout at that value, server still finishing |
| LB processing time bimodal (ms and seconds) on one endpoint | Cache miss or a single slow dependency on that path |
| Same endpoint slow on every pod, others fast on the same pods | Code path or datastore, not the pod or node |
| PI load on one SQL equal to the count of concurrent slow requests for their exact duration | That query is the bottleneck |
| `wait/io/table/sql/handler` with high rows read per second | Row scan, check `EXPLAIN` and indexes |

## Validation

- Per-bucket counts of client disconnects and app requests over the caller timeout differ by no more than a few percent
- Every chart time axis is KST and the window edges in TLDR match the charts
- `grep -nE 'Bearer|eyJ[A-Za-z0-9_-]{10,}' <report>` returns nothing
- writing-style Validation greps pass on the report body
