---
name: bash-generator
description: Write Bash scripts that run unchanged on macOS (BSD userland) and Linux CI, pass shellcheck, and follow the user's script conventions.
when_to_use: Creating automation, deployment, CI helper, or admin shell scripts, e.g. "스크립트 작성", "쉘 스크립트로 만들어줘". Not for workflow `run:` steps (use github-actions-generator) or Dockerfile `RUN` instructions (use dockerfile-generator).
argument-hint: "[script purpose]"
license: Apache-2.0
compatibility: bash 3.2+ (macOS default) and bash 5 (Linux); shellcheck
metadata:
  version: "2.1.0"
  category: generator
  related: github-actions-generator
allowed-tools: Bash(shellcheck *) Bash(bash -n *) Bash(/bin/bash *) Read Write Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Bash

Strict mode, quoting, `trap` cleanup, `local`, and `usage()` are assumed. Comments follow the global Code Comments rule.

## Portability

- Same script works on macOS and Linux: no `sed -i` without a backup-suffix shim, no GNU-only flags (`date -d`, `readlink -f`, `grep -P`). Prefer epoch math or jq/awk over a branch, and when a branch is unavoidable detect GNU with `<tool> --version`
- No bash 4+ features (associative arrays, `${var,,}`, `mapfile`) unless the shebang targets a Homebrew bash explicitly
- Arrays that can be empty expand as `${arr[@]+"${arr[@]}"}`, since bare `"${arr[@]}"` aborts under `set -u` on bash 3.2
- Iterate lines with `while IFS= read -r`, never `for x in $(...)`
- Commands inside a `while read` loop that read stdin (`ssh`, `kubectl exec`) get `</dev/null`

## Behavior

- Logs to stderr, data to stdout
- Destructive scripts support `--dry-run`, and affected items go to stdout in both modes
- Secrets come from the environment or a credential helper, never arguments or files in the repo
- Required tools checked with `command -v` up front with a clear message

## Validation

- `bash -n` and `shellcheck` pass with no warnings
- Script runs under `/bin/bash` 3.2 on macOS, since neither check catches bash 4+ expansions or builtins
