---
name: falco-rules
description: Generate and tune Falco custom rules, exceptions, macros, and override syntax.
when_to_use: Adding Falco exception tuning, writing custom detection rules, or troubleshooting rule loading errors, e.g. "falco 오탐 예외 추가", "falco 룰 작성". Not for chart structure (use helm-chart), chart or image version bumps (use helm-bump), or the kernel drop PrometheusRule (use promql-generator).
argument-hint: "[rule name or alert output]"
license: Apache-2.0
compatibility: falco binary or the falcosecurity/falco image (podman or docker) for --validate, helm for rendering customRules; kubectl for reading Falco pod logs
metadata:
  version: "1.3.0"
  category: generator
  related: k8s-manifest helm-chart helm-bump promql-generator
allowed-tools: Bash(falco *) Bash(podman run *) Bash(docker run *) Bash(helm template *) Bash(kubectl logs *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Falco Rules Generator

Generate and tune Falco custom rules, exceptions, and macros for runtime security.

## Output Requirements

- Use `override` syntax, never deprecated `append: true`
- Exception scope is minimal: specific field combinations over broad exclusions
- Environment scope follows where the workload runs: add the same exception to every environment by default, but a workload that runs only in some clusters gets its exception only there; never sync those to other environments
- Env-only rules go in their own `customRules` key in that env values file (for example `rules-prod.yaml`) so the Helm map merge keeps the common `rules-custom.yaml`. List values such as falcoctl `refs` are replaced, not merged
- Extend the existing `falco` namespace and DaemonSet (extra sources, extra rules) instead of creating a new namespace or Falco instance
- Native buildkit builds on runners report `container.id=host`, so buildkit exceptions key on `[container.id, proc.aname] = [host, buildkitd]`, not a `buildkit/` container.id prefix
- Validate override files together with every ruleset that defines the target rule
- Comments follow the global Code Comments rule

## Sensor And Response

- Syscall source uses the modern eBPF driver on a DaemonSet that tolerates every taint. Managed nodes do not allow kernel modules
- Kubernetes API abuse (`pods/exec`, Secret deletion, privileged pod creation) is invisible to syscalls and needs the `k8saudit-eks` plugin reading EKS audit logs
- JSON output with container and Kubernetes metadata, so every alert names namespace, pod, image, and command line
- Kernel event drops from Falco metrics are alerted on. A silent sensor is a detection gap
- Rules scoped to application namespaces, platform namespaces excluded with macros and exceptions. Debug and break-glass namespaces get their own exception, never a lower priority for everyone
- Benign activity from the stack (agent wrappers, probes) is allowlisted before any automated action

| Priority | Example | Response |
|----------|---------|----------|
| WARNING | Interactive shell in an app container (`proc.tty != 0`) | Falco Talon labels the pod, no notification |
| ERROR | Write under `/etc`, package manager in a container | Falcosidekick notifies the team channel |
| CRITICAL | `/etc/shadow` read, instance metadata access, outbound connection from a shell | Notify, then Talon terminates the pod after a short grace period |

Talon actions match specific rule names, never every CRITICAL alert.

## Override Syntax (Falco 0.35+)

Built-in rule changes use `override: { <key>: append | replace }` (for example `exceptions: append`, `condition: append`, `priority: replace`):

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

### Field Selection Guide

| Context | Recommended fields |
|---------|-------------------|
| Host process | `container.id`, `proc.name` |
| Container health check | `container.image.repository`, `proc.name` |
| Namespace-scoped | `k8s.ns.name`, `k8s.pod.name` |
| Native buildkit on runner host | `container.id` (= host), `proc.aname` (= buildkitd) |

## Custom Rule Structure

New rules need no `override`. Redefining a built-in by name replaces it and leaves its macros unused (`LOAD_UNUSED_MACRO`), so prefer `override`. This example uses `package_mgmt_procs` and `package_mgmt_ancestor_procs` from the sandbox ruleset:

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

- No macOS falco binary: run `falco --validate` in `falcosecurity/falco:<chart appVersion>` with podman or docker, mounting the sandbox ruleset and the custom files rendered by `helm template`
- `k8s_audit` rules validate only with the `k8saudit-eks` and `json` plugins loaded through a Falco config

```bash
# Dry-run rule validation: base rulesets first, then the custom files
falco --validate /etc/falco/falco_rules.yaml \
  --validate /etc/falco/falco-sandbox_rules.yaml \
  --validate /etc/falco/rules.d/<file>.yaml

# Check hot reload logs after ConfigMap update
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco --tail=20 | grep -E "Loading|Error|Warning|complete"

# End-to-end after rollout: expect a CRITICAL alert, a notification, and the Talon action
kubectl run falco-test --image=busybox:1.37 --restart=Never -it --rm -- sh -c \
  'cat /etc/shadow; wget -qO- -T 2 http://169.254.169.254/latest/meta-data/'
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Item has no mapping for key 'enabled'` | Missing `override` on built-in rule modification | Add `override: { exceptions: append }` |
| `LOAD_ERR_VALIDATE ... no rule by that name already exists` | Target rule's ruleset not loaded (sandbox rules need the `falco-sandbox-rules` falcoctl ref and a `rules_files` entry) | Load the defining ruleset first |
| `LOAD_DEPRECATED_ITEM` (warning) | Using `append: true` | Migrate to `override` syntax |
| `hot restart failure` | Rule parsing failed | Check `falco` container logs for `LOAD_ERR` details |
