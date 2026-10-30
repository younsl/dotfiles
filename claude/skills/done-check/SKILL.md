---
name: done-check
description: Verification gate and evidence-based status report before calling work done, committing, or releasing, covering Rust, Go, Helm, Terraform, Kubernetes YAML, CI workflows, Dockerfiles, docs, and release readiness.
when_to_use: Requests such as "작업 완료인가?", "구현 완료인가?", "남은 작업은?", "릴리즈 준비된건가?", "cargo fmt, cargo clippy 검증", "gofmt, go fix 적용", "다시 확인해줘", and automatically after finishing any implementation. Not for committing or pushing (use git-ship), re-releasing (use release-retrigger or rust-bump-rerelease), or post-release status (use release-promote).
argument-hint: "[path or version]"
license: Apache-2.0
compatibility: Uses whichever toolchains the change touches (cargo, cargo-llvm-cov, go, helm, helm-docs, kubeconform, terraform, terragrunt, actionlint, glab, hadolint, docker); missing tools are reported as not run
metadata:
  version: "1.1.0"
  category: validator
  related: git-ship release-retrigger rust-bump-rerelease writing-style helm-chart k8s-manifest terraform-generator
allowed-tools: Bash(cargo *) Bash(go *) Bash(gofmt *) Bash(make *) Bash(helm *) Bash(helm-docs *) Bash(kubeconform *) Bash(terraform *) Bash(terragrunt *) Bash(actionlint *) Bash(glab ci lint*) Bash(hadolint *) Bash(docker build *) Bash(grep *) Bash(git *) Read Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Done Check

Answer "is it done?" with evidence, not memory of what was attempted.

## Output Requirements

- Gate runs on the files changed in the task (`git diff --name-only` against the merge base plus untracked)
- Repo targets (`Makefile`, `justfile`, CI config) replace the table checks they cover; table checks they do not cover still run
- Every check is reported as passed, failed (with the decisive error line), or not run (with reason); never claim a check that did not run
- Auto-fixers (`cargo fmt`, `gofmt -w`, `go fix`) are applied, not just reported, except in vendored or third-party code
- Report ends with a verdict line: done, or a numbered list of remaining items with owner (Claude or user)

## Gate by Change Type

| Changed | Checks |
|---------|--------|
| Rust | `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`; before a release `cargo llvm-cov --fail-under-lines 70` (or the repo `coverage` target), below threshold is failed |
| Go | `gofmt -l` empty, `go fix ./...` repeated until no diff, `go vet ./...`, `go test ./...` |
| Helm chart | `helm-chart` skill Validation (`helm lint --strict`, `helm template` per values file piped to `kubeconform -strict`, `helm unittest`, helm-docs) |
| Terraform | `terraform-generator` skill Validation (`terraform fmt -check -recursive` or `terragrunt hclfmt --check`, `validate`) |
| Kubernetes YAML | `k8s-manifest` skill Validation (`kubeconform -strict` with CRD schemas; server-side dry-run only where cluster access exists) |
| GitHub Actions workflow | `actionlint` with the repo `.github/actionlint.yaml` declaring the `ubuntu-26.04*` runner labels (github-actions-generator Validation). A missing config is reported, never bypassed with `-ignore` |
| GitLab CI | `glab ci lint` |
| Dockerfile | `hadolint`, `docker build` for the native arch only; the non-native arch is built by CI and reported as not run |
| Docs / MR text | `writing-style` skill validation greps |

## Release Readiness (for "릴리즈 준비된건가?")

- Scope is everything since the last release (its tag, else the commit that last changed the version string), and the full gate above runs on it
- Working tree clean and `HEAD` equals its upstream after `git fetch`
- Version strings agree (`Cargo.toml`, `Cargo.lock`, Dockerfile version label, `Chart.yaml` `version`/`appVersion`, `values.yaml` `image.tag`, README badges, Go ldflags or `VERSION`); `helm template` renders the expected image tag
- Target version not already published (git tag, or the registry artifact for repos that release on push without tags) unless this is an intended re-release
- Toolchain-only bump plus re-release skips the local lint loop and goes straight to commit and dispatch

## Remaining Work Sources

- Uncommitted or unpushed changes, open MR with stale description, failing pipeline on the branch

## Validation

- Verdict matches the check results
