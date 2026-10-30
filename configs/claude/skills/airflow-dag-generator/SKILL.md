---
name: airflow-dag-generator
description: Generate production-ready Apache Airflow DAGs with low parse cost and idempotent tasks.
when_to_use: Writing or refactoring DAGs, tasks, operators, or sensors, e.g. "DAG 작성", "airflow dag 개발", "DAG 파싱 느림". Not for Airflow Helm values or cluster manifests (use helm-chart, k8s-manifest).
argument-hint: "[dag purpose]"
license: Apache-2.0
compatibility: Python 3 with apache-airflow 3.x (verified 3.3.2, 3.0.6 fails under uv no-build) for airflow dags test and dags report; ruff for lint and pytest for DAG tests
metadata:
  version: "1.2.0"
  category: generator
  related: k8s-manifest helm-chart
  upstream-docs: https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html
allowed-tools: Bash(airflow *) Bash(ruff *) Bash(python3 *) Bash(pytest *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Airflow DAG Generator

Target Airflow 3.x. Refactors keep the target cluster's Airflow major version: confirm before moving a 2.x DAG to `airflow.sdk`. Standard practices (retries, `owner`, tags, docstrings) apply without restating them. Comments follow the global Code Comments rule. Below are the constraints that decide whether a DAG survives production.

## Parse Cost Is The Budget

The scheduler re-parses every DAG file on a fixed interval. Anything at module top level runs on every parse, on every scheduler process.

| Rule | Reason |
|------|--------|
| No `Variable.get()` / `Connection.get()` at top level | One DB query per parse cycle. Use `{{ var.value.name }}` in templated fields, or fetch inside the callable |
| No API calls, file reads, or heavy imports at top level | Same cost, unbounded latency. Move into the task callable |
| DAG shape never derived from an API, DB, or Variable at parse time | Fan out with `.partial().expand()` over an upstream task's output, not a top-level loop. Task ids stay static |
| No DB access in a custom timetable's `__init__` | Runs during parse. Defer to execution time |
| One DAG per file, dependencies linear over deeply nested | Parse time and scheduler dependency resolution both scale with this |

Top level holds only what builds the operators and the dependency graph.

## Idempotency

A task must produce the same result when rerun for the same logical date.

- `UPSERT` / `MERGE` (`INSERT ... ON CONFLICT DO UPDATE` counts), never bare `INSERT`
- Read a partition keyed on the logical date, never "latest"
- `datetime.now()` / `time.time()` banned in anything that affects output. Use `{{ data_interval_start }}`, `{{ data_interval_end }}`, `{{ ds }}`. Audit columns such as `loaded_at` may use DB `now()`, set only when the row changes
- `ds` and `ds_nodash` are UTC dates. For a non-UTC schedule, derive the partition date from `data_interval_start.in_timezone(<dag tz>)`
- No partial writes. Stage first, then either swap atomically or upsert plus delete-missing in one transaction

## Task Boundaries

| Concern | Rule |
|---------|------|
| Inter-task data | XCom for small scalars and keys only. Payloads go to object storage, pass the URI through XCom |
| Local filesystem | Never shared between tasks. Distributed executors place downstream tasks on other workers |
| Credentials | Airflow Connections only. Never literals, never Variables holding secrets |
| Environment coupling | Bucket names, cluster ids, endpoints come from Variables or env vars, never hardcoded, so the same file runs in staging |
| Long waits | Sensors run `deferrable=True`, or `mode="reschedule"` when the sensor has no trigger. Never poke mode for waits over a few minutes |

## Dependency Isolation

When a task needs libraries that conflict with the scheduler environment:

| Operator | Use when |
|----------|----------|
| `PythonVirtualenvOperator` | Iterating in development. Builds the venv per run, costs CPU each time |
| `ExternalPythonOperator` | Production equivalent of the above. Prebuilt immutable interpreter, no per-run build |
| `KubernetesPodOperator` | System-level dependencies, non-Python work, or hard resource isolation. Pays pod startup |

Default to no isolation. Reach for it only on an actual conflict.

## Airflow 3 Imports

`dag`, `task`, `chain`, `Variable`, `Connection`, `Asset`, `BaseOperator`, `BaseSensorOperator` come from `airflow.sdk`. Stock operators and sensors come from `airflow.providers.standard.*`. Never `airflow.operators.*` / `airflow.decorators`. Other renames are enforced by `ruff --select AIR`.

## Validation

```bash
python3 dags/<dag_file>.py         # import errors
ruff check dags/ --select AIR      # deprecated and Airflow 3 incompatible patterns
airflow dags report -o plain       # per-file parse duration, needs a migrated metadata DB
pytest tests/                      # DB-free structure and parse tests
airflow dags test <dag_id> <date>  # real execution, needs a migrated metadata DB and reachable connections
```

Per-file duration in `dags report` above ~0.5s means top-level code leaked in. Wall time of `python3 <file>` is dominated by importing Airflow (~1s) and does not measure the DAG.

Unit tests assert DAG structure and custom operator logic with no DB. Mock state through env vars, `AIRFLOW_VAR_{KEY}` and `AIRFLOW_CONN_{CONN_ID}`, with `unittest.mock.patch.dict`. The parse test patches `requests`, `Variable.get`, and `Connection.get` to raise during import, so parse-time I/O fails CI. Deferrable operators assert the deferral and trigger, then exercise the resume method.

Add a downstream self-check task when the output is consumed elsewhere: assert the partition exists and the row count is sane rather than trusting a green task.
