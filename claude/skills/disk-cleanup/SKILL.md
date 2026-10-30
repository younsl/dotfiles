---
name: disk-cleanup
description: Reclaim local filesystem free space on a macOS workstation by aggressively clearing rebuildable build artifacts, package manager caches, unused container images and non-default Rust toolchains, while leaving in-use caches and user data untouched.
when_to_use: Freeing disk space on the local machine, e.g. "디스크 공간 확보", "로컬 디스크 정리", "디스크 사용률 90% 넘음", "캐시 정리", "빌드 산출물 정리". Not for node or volume disk on servers or Kubernetes (use k8s-manifest or terraform-generator) or for writing a new cleanup script (use bash-generator).
license: Apache-2.0
compatibility: macOS with APFS; optional go, cargo, rustup, uv, npm, pnpm, brew, mise, podman
metadata:
  version: "2.0.0"
  category: action
  related: bash-generator done-check
allowed-tools: Bash(*/disk-cleanup/scripts/disk-cleanup.sh *) Bash(df *) Bash(pgrep *) Bash(rustup toolchain list) Bash(podman ps *) Read Grep
user-invocable: true
disable-model-invocation: false
---

# Disk Cleanup

## Output Requirements

- One run of `scripts/disk-cleanup.sh` (in this skill's base directory) does the whole cleanup; no per-item commands, no `--dry-run` first unless the user asks for a preview
- The script runs in the background with its stdout (TSV) redirected to a scratchpad file; the report is built from that file
- Only rebuildable data is deleted: build outputs, download caches, unused images, non-default toolchains
- Rust keeps only the toolchain from `rustup default`; `stable` and channels pinned in `rust-toolchain.toml` are removed and re-download on the next build in those repos
- Project build outputs (`target`, `node_modules`, `dist`, `.zig-cache`, `.terragrunt-cache`) are removed only when git ignores them, or outside git when the matching `Cargo.toml` or `package.json` sits next to them
- An item in use by a live process is skipped, never forced; the report names the blocking process by name only
- Process listings use process names; full command lines can carry inline secrets and never go into the report
- Reclaimed size per item is the `df` free-space delta, so concurrent writes can make it read low

## Never Touch

| Path | Reason |
|------|--------|
| `~/.ssh`, `~/.aws`, `~/.kube`, `~/.gnupg`, `~/.docker` | Credentials |
| `~/Library/Application Support`, browser profile and cache dirs | App state, logins |
| `~/Downloads`, `~/Documents`, `~/Desktop` | User data |
| `~/.claude/projects`, `~/.claude/history.jsonl` | Session history used for recall |
| Podman volumes, containers (running or stopped) and their images | Persistent data, kind clusters |
| Git-tracked or untracked-but-not-ignored files, stashes | Uncommitted work |
| Time Machine local snapshots, `~/.ollama/models` | Backups, hand-pulled models |

## Reference

| Symptom | Cause |
|---------|-------|
| `partial: still being written` | A build wrote into the directory during removal; rerun after it ends |
| `~/.cache/uv (current buckets)` skipped | `uvx` processes (MCP servers) hold the cache; only stale `*-vN` buckets go |
| `go build ... cache` skipped with `go` | A `go test` or `go build` is running, often an e2e suite with a kind cluster |
| `podman` reclaimed less than the dry run | Images still referenced by stopped containers stay |
| A repo's `target` reappears within minutes | rust-analyzer or a watcher rebuilt it; not a failed removal |

## Report

- Capacity before and after from the script's stderr
- Table of `removed` rows, largest first; group the many `.terragrunt-cache` and `dist` rows into one line each with count and sum
- `skipped` rows with the blocking process
- Toolchain kept and toolchains removed

## Validation

- `df -h /System/Volumes/Data` shows lower `Used` than baseline
- `rustup toolchain list` shows only the default toolchain
- `podman ps -a` lists the same containers as before cleanup
- `pgrep -l` shows previously running MCP or dev servers still alive
