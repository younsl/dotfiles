---
name: helm-chart
description: Author, extend, and review Helm charts and wrapper-chart values following the user's chart conventions.
when_to_use: Creating a chart, adding templates or values keys, supporting a new resource such as HTTPRoute or extraObjects, adding a chart to a new environment, adding or reviewing values.schema.json, or reviewing chart changes, e.g. "차트에서 HTTPRoute 지원해줘", "values.schema.json 추가", "extraObjects 템플릿 추가", "새 환경에 차트 추가", "차트 검증". Not for chart or image version bumps and upstream values sync (use helm-bump), raw manifests outside a chart (use k8s-manifest), PromQL expressions inside a PrometheusRule (use promql-generator), Falco rule content (use falco-rules), or commit, push, and MR (use git-ship).
argument-hint: "[chart path]"
license: Apache-2.0
compatibility: helm, kubeconform, helm-docs; helm-unittest when the chart has tests
metadata:
  version: "2.2.0"
  category: generator
  related: helm-bump k8s-manifest done-check
allowed-tools: Bash(helm *) Bash(helm-docs *) Bash(kubeconform *) Bash(git diff *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Helm Chart

Standard chart practice applies without restating it. Below are the user's conventions. No chart named: infer from cwd or the diff, else ask.

## values.yaml

- Every leaf key has a helm-docs annotation on the line above: `# -- (type) one short line`, no semicolon, even where neighbors use one. Never inline after the value, never multi-line. Parent maps follow the chart
- Comments beyond the annotation follow the global Code Comments rule
- New knobs are a last resort: derive safety features (PDB, leader election) from existing values such as `replicaCount` or an enable flag
- Do not add a `resources` key to components that lack one; absence means "follow upstream defaults"
- Block sequences indented two spaces under their key; RBAC `apiGroups`, `resources`, `verbs` as `-` lines, never flow arrays

## Wrapper Charts

- values.yaml under the dependency key is the full `helm show values` output of the pinned version, comments intact, with only overrides changed; never a trimmed subset
- Same rule for each alias of the same dependency and for each new environment: copy the existing environment's file and change only environment values
- Unsets use explicit `null` (rule owned by helm-bump)
- Disabling a feature keeps the upstream default block with `enabled: false`, not a collapsed one-liner
- `Chart.yaml` `deprecated: true` only when the whole addon is being removed; per-environment shutdown is `enabled: false`
- Respect upstream internal-default blocks (e.g. Istio `_internal_defaults_do_not_set`): override at the top level, never inside

## values.schema.json

- Every first-party chart ships one: draft-07, hand-written, shared shapes under `definitions`. Wrapper charts rely on the upstream schema
- Strict where the chart owns the shape: root keys, app `config`, user-defined maps (`propertyNames` pattern + `additionalProperties: false`)
- Open for Kubernetes pass-through fields (`resources`, `affinity`, `tolerations`, `securityContext`, probes, `dnsConfig`): `type` only, never re-declare Kubernetes schemas
- Subchart keys and `global` declared at the root as open `object`, subchart internals left to the subchart schema
- Fields users unset with `null` allow it, e.g. `["object", "null"]`
- A new values key and its schema entry land in the same change
- A feature or schema addition warrants a minor chart `version` bump: report it, bump only when asked. Render consumer override files first, since stale keys now fail
- No generator plugin (helm-values-schema-json): it over-constrains pass-through fields

## templates/

- One resource kind per file; `extra-objects.yaml` (a `range` with `tpl`) is the only multi-object file
- No `#` comments in templates; Go template comments only when unavoidable
- Conditional values as multi-line `if`/`else` blocks wrapping the key, not inline ternaries
- Optional features follow the existing toggle idiom of the chart (e.g. `{{- if .Values.x.enabled }}`). CRD kinds also check `.Capabilities.APIVersions.Has "<group/version/Kind>"`
- Reference blocks render every identifying field from the k8s-manifest table unconditionally, never behind `if`, even where existing chart templates do
- Container field rules (`resizePolicy` after `resources`) come from k8s-manifest

## Review Output

Target is the named commit or path, else the uncommitted diff plus commits ahead of the default branch. Findings ranked by severity, one line each with `file:line`, then the validation results. Checks masked by a blocker run on a patched copy labeled probe. No praise, no restating unchanged code.

## Validation

- `helm lint --strict` and `helm template` for every values file in use, with `--api-versions <group/version/Kind>` for each `.Capabilities`-guarded kind, piped to `kubeconform -strict` with CRD schemas from the catalog
- A values file with a misspelled root or `config` key fails `helm template`
- `helm unittest` when `tests/` exists
- `helm-docs --sort-values-order=file` regenerated when annotations changed. `git diff -U0 -- values.yaml | grep '^+.*# -- ' | awk 'length($0)>121'` returns nothing
- Wrapper chart: `helm show values <chart> --version <v>` diffed against the dependency block leaves only intended overrides
