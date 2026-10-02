---
name: done-check
description: Verification gate and evidence-based status report before calling work done, committing, or releasing, covering Rust, Go, Helm, Terraform, Kubernetes YAML, docs, and release readiness.
when_to_use: Requests such as "작업 완료인가?", "구현 완료인가?", "남은 작업은?", "릴리즈 준비된건가?", "cargo fmt, cargo clippy 검증", "gofmt, go fix 적용", "다시 확인해줘", and automatically after finishing any implementation.
argument-hint: "[path or version]"
license: Apache-2.0
compatibility: Uses whichever toolchains the change touches (cargo, go, helm, terraform); missing tools are reported as not run
metadata:
  version: "1.0.0"
  category: validator
  related: git-ship release-retrigger rust-bump-rerelease writing-style
allowed-tools: Bash(cargo *) Bash(go *) Bash(gofmt *) Bash(make *) Bash(helm *) Bash(terraform *) Bash(git *) Read Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Done Check

Answer "is it done?" with evidence, not memory of what was attempted.

## Output Requirements

- Gate runs on the files changed in the task (`git diff --name-only` against the merge base plus untracked)
- Repo targets win: if `Makefile`, `justfile`, or CI config defines lint/test targets, run those instead of the table defaults
- Every check is reported as passed, failed (with the decisive error line), or not run (with reason); never claim a check that did not run
- Auto-fixers (`cargo fmt`, `gofmt -w`, `go fix`) are applied, not just reported, except in vendored or third-party code
- Report ends with a verdict line: done, or a numbered list of remaining items with owner (Claude or user)

## Gate by Change Type

| Changed | Checks |
|---------|--------|
| Rust | `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`; add coverage tool before a release |
| Go | `gofmt -l` empty, `go fix ./...` repeated until no diff, `go vet ./...`, `go test ./...` |
| Helm chart | `helm lint`, `helm template` per values file, `helm unittest` if tests exist, helm-docs regenerated when values comments changed |
| Terraform | `terraform fmt -check -recursive`, `terraform validate` |
| Kubernetes YAML | Server-side dry-run or schema validation; never `kubectl port-forward` |
| Docs / MR text | `writing-style` skill validation greps |
| Dockerfile | Build for both `linux/amd64` and `linux/arm64` when the image is multi-arch |

## Release Readiness (for "릴리즈 준비된건가?")

- Working tree clean and `HEAD` pushed
- Version strings agree across manifest files (`Cargo.toml`/`go.mod` tooling, Dockerfile version label, `Chart.yaml` `version`/`appVersion`, README badges)
- Target tag does not already exist unless this is an intended re-release
- Re-release keeps the same version; a version bump is a different task
- Toolchain-only bump plus re-release skips the local lint loop and goes straight to commit and dispatch

## Remaining Work Sources

- Open TODOs from this session's plan or task list
- Uncommitted or unpushed changes, open MR with stale description, failing pipeline on the branch
- Follow-ups the user requested earlier in the session but not yet done

## Validation

- Each reported pass maps to a command actually run in this turn
- Verdict matches the check results
