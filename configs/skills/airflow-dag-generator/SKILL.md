---
name: airflow-dag-generator
description: Generate production-ready Apache Airflow DAGs. Use when writing or refactoring DAGs, tasks, operators, sensors, or Airflow deployment code.
metadata:
  upstream-docs: https://airflow.apache.org/docs/apache-airflow/stable/best-practices.html
---

# Airflow DAG Generator

Target Airflow 3.x. Standard practices (retries, `owner`, tags, docstrings, `catchup=False` unless backfill is intended) apply without restating them. Below are the constraints that decide whether a DAG survives production.

## Parse Cost Is The Budget

The scheduler re-parses every DAG file on a fixed interval. Anything at module top level runs on every parse, on every scheduler process.

| Rule | Reason |
|------|--------|
| No `Variable.get()` / `Connection.get()` at top level | One DB query per parse cycle. Use `{{ var.value.name }}` in templated fields, or fetch inside the callable |
| No API calls, file reads, or heavy imports at top level | Same cost, unbounded latency. Move into the task callable |
| No DB access in a custom timetable's `__init__` | Runs during parse. Defer to execution time |
| One DAG per file, dependencies linear over deeply nested | Parse time and scheduler dependency resolution both scale with this |

Top level holds only what builds the operators and the dependency graph.

## Idempotency

A task must produce the same result when rerun for the same logical date.

- `UPSERT` / `MERGE`, never bare `INSERT`
- Read a partition keyed on the logical date, never "latest"
- `datetime.now()` / `time.time()` banned in anything that affects output. Use `{{ data_interval_start }}`, `{{ data_interval_end }}`, `{{ ds }}`
- No partial writes. Write to a staging location, then atomically swap

## Task Boundaries

| Concern | Rule |
|---------|------|
| Inter-task data | XCom for small scalars and keys only. Payloads go to object storage, pass the URI through XCom |
| Local filesystem | Never shared between tasks. Distributed executors place downstream tasks on other workers |
| Credentials | Airflow Connections only. Never literals, never Variables holding secrets |
| Environment coupling | Bucket names, cluster ids, endpoints come from Variables or env vars, never hardcoded, so the same file runs in staging |

## Dependency Isolation

When a task needs libraries that conflict with the scheduler environment:

| Operator | Use when |
|----------|----------|
| `PythonVirtualenvOperator` | Iterating in development. Builds the venv per run, costs CPU each time |
| `ExternalPythonOperator` | Production equivalent of the above. Prebuilt immutable interpreter, no per-run build |
| `KubernetesPodOperator` | System-level dependencies, non-Python work, or hard resource isolation. Pays pod startup |

Default to no isolation. Reach for it only on an actual conflict.

## Airflow 3 Migration Traps

`schedule_interval` is `schedule`. `execution_date` is `logical_date`. Datasets are Assets. Task SDK imports come from `airflow.sdk`, not `airflow.operators.*` / `airflow.decorators`.

## Validation

```bash
time python dags/<dag_file>.py     # import errors + parse cost in one shot
ruff check dags/ --select AIR      # deprecated and Airflow 3 incompatible patterns
airflow dags test <dag_id> <date>  # real execution, no scheduler needed
```

Parse time above ~1s per file means top-level code leaked in.

Unit tests assert DAG structure and custom operator logic with no DB. Mock state through env vars, `AIRFLOW_VAR_{KEY}` and `AIRFLOW_CONN_{CONN_ID}`, with `unittest.mock.patch.dict`. Deferrable operators assert the deferral and trigger, then exercise the resume method.

Add a downstream self-check task when the output is consumed elsewhere: assert the partition exists and the row count is sane rather than trusting a green task.
