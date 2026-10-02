---
name: helm-chart
description: Author, extend, and review Helm charts and wrapper-chart values following the user's chart conventions.
when_to_use: Creating a chart, adding templates or values keys, supporting a new resource such as HTTPRoute or extraObjects, adding a chart to a new environment, or reviewing chart changes, e.g. "차트에서 HTTPRoute 지원해줘", "extraObjects 템플릿 추가", "새 환경에 차트 추가", "차트 검증". Not for version bumps (use helm-bump).
argument-hint: "[chart path]"
license: Apache-2.0
compatibility: helm, kubeconform, helm-docs; helm-unittest when the chart has tests
metadata:
  version: "2.0.0"
  category: generator
  related: helm-bump k8s-manifest done-check
allowed-tools: Bash(helm *) Bash(helm-docs *) Bash(kubeconform *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Helm Chart

Standard chart practice (`_helpers.tpl` names and labels, `include` + `nindent`, `.Release.Namespace`, `required`, secure `securityContext`, configurable scheduling, external CRDs guarded by `.Capabilities.APIVersions.Has`) applies without restating it. Below are the user's conventions.

## values.yaml

- Every key has a helm-docs annotation on the line above: `# -- (type) one short line`; never inline after the value, never multi-line
- Comments beyond the annotation follow the global Code Comments rule
- Never edit or delete existing comments, including upstream originals, unless asked
- New knobs are a last resort: derive safety features (PDB, leader election) from existing values such as `replicaCount` or an enable flag
- Do not add a `resources` key to components that lack one; absence means "follow upstream defaults"
- Block sequences indented two spaces under their key; RBAC `apiGroups`, `resources`, `verbs` as `-` lines, never flow arrays
- No Kubernetes version notes in comments or docs

## Wrapper Charts

- values.yaml under the dependency key is the full `helm show values` output of the pinned version, comments intact, with only overrides changed; never a trimmed subset
- Same rule for each alias of the same dependency and for each new environment: copy the existing environment's file and change only environment values
- Unset an upstream default with explicit `null`; deleting the key does not unset it under map merge
- Disabling a feature keeps the upstream default block with `enabled: false`, not a collapsed one-liner
- `Chart.yaml` `deprecated: true` only when the whole addon is being removed; per-environment shutdown is `enabled: false`
- Respect upstream internal-default blocks (e.g. Istio `_internal_defaults_do_not_set`): override at the top level, never inside

## templates/

- One resource kind per file; `extra-objects.yaml` (a `range` with `tpl`) is the only multi-object file
- No `#` comments in templates; Go template comments only when unavoidable
- Conditional values as multi-line `if`/`else` blocks wrapping the key, not inline ternaries
- Optional features follow the existing toggle idiom of the chart, e.g. `{{- if ((.Values.x).enabled) | default false }}`
- Reference blocks spell out every identifying field: HTTPRoute `parentRefs` with `group`, `kind`, `name`, `namespace`; same for `backendRefs`
- Container `resizePolicy` sits right after `resources` as a sibling

## Review Output

Findings ranked by severity, one line each with `file:line`, then the validation results. No praise, no restating unchanged code.

## Validation

- `helm lint --strict` and `helm template` for every values file in use, piped to `kubeconform -strict`
- `helm unittest` when `tests/` exists
- `helm-docs --sort-values-order=file` regenerated when annotations changed; `awk 'length($0)>120 && /# -- /' values.yaml` returns nothing
- Wrapper chart: `helm show values <chart> --version <v>` diffed against the dependency block leaves only intended overrides
