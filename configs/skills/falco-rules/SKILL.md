---
name: falco-rules
description: Generate and tune Falco custom rules, exceptions, macros, and override syntax.
when_to_use: Adding Falco exception tuning, writing custom detection rules, or troubleshooting rule loading errors, e.g. "falco 오탐 예외 추가", "falco 룰 작성".
argument-hint: "[rule name or alert output]"
license: Apache-2.0
compatibility: falco binary for --validate; kubectl for reading Falco pod logs
metadata:
  version: "1.1.0"
  category: generator
  related: k8s-manifest helm-chart
allowed-tools: Bash(falco *) Bash(kubectl logs *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Falco Rules Generator

Generate and tune Falco custom rules, exceptions, and macros for runtime security.

## Output Requirements

- Use `override` syntax, never deprecated `append: true`
- Exception scope is minimal: specific field combinations over broad exclusions
- Environment scope follows where the workload runs: add the same exception to every environment by default, but a workload that runs only in some clusters gets its exception only there; never sync those to other environments
- Extend the existing `falco` namespace and DaemonSet (extra sources, extra rules) instead of creating a new namespace or Falco instance
- Native buildkit builds on runners report `container.id=host`, so buildkit exceptions cannot rely on the `buildkit/` prefix alone
- Comments follow the global Code Comments rule

## Override Syntax (Falco 0.35+)

`append: true` is deprecated. Use `override` with the target key and `append`/`replace`:

| Action | Syntax |
|--------|--------|
| Add exceptions to built-in rule | `override: { exceptions: append }` |
| Append condition to built-in rule | `override: { condition: append }` |
| Replace priority of built-in rule | `override: { priority: replace }` |

```yaml
- rule: Create Hardlink Over Sensitive Files
  override:
    exceptions: append
  exceptions:
    - name: adduser_user_creation
      fields: [proc.name]
      comps: [=]
      values:
        - [adduser]
```

## Exception Structure

```yaml
exceptions:
  - name: <snake_case_name>
    fields: [field1, field2]
    comps: [operator1, operator2]
    values:
      - [value1, value2]       # row 1 (AND within row)
      - [value1_alt, value2_alt] # row 2 (OR between rows)
```

### Field Selection Guide

| Context | Recommended fields |
|---------|-------------------|
| Host process | `container.id`, `proc.name` |
| Container health check | `container.image.repository`, `proc.name` |
| Namespace-scoped | `k8s.ns.name`, `k8s.pod.name` |
| Build system (buildkit) | `container.id` (startswith), `proc.cmdline` (contains) |

## Custom Rule Structure

Full rule definition replaces the built-in rule entirely (no `override` needed):

```yaml
- rule: Package management process launched
  desc: >
    Package management process ran on host or inside container.
  condition: >
    spawned_process
    and package_mgmt_procs
    and not package_mgmt_ancestor_procs
  output: >
    Package management process launched
    (container_id=%container.id command=%proc.cmdline k8s_ns=%k8s.ns.name k8s_pod=%k8s.pod.name)
  priority: WARNING
  tags: [host, container, process, mitre_persistence]
  exceptions:
    - name: host_dnf_automatic
      fields: [container.id, proc.name]
      comps: [=, =]
      values:
        - [host, dnf]
        - [host, rpm]
```

## Validation

```bash
# Dry-run rule validation (inside Falco container)
falco --validate /etc/falco/rules.d/rules-custom.yaml

# Check hot reload logs after ConfigMap update
kubectl logs -l app.kubernetes.io/name=falco -c falco --tail=20 | grep -E "Loading|Error|Warning|complete"
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Item has no mapping for key 'enabled'` | Missing `override` on built-in rule modification | Add `override: { exceptions: append }` |
| `LOAD_DEPRECATED_ITEM` | Using `append: true` | Migrate to `override` syntax |
| `hot restart failure` | Rule parsing failed | Check `falco` container logs for `LOAD_ERR` details |
