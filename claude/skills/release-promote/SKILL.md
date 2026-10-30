---
name: release-promote
description: Check a release pipeline, mirror the released multi-arch image and OCI chart to the internal registry, and bump consumer charts in the GitOps repo.
when_to_use: Requests such as "릴리즈 상태 확인", "릴리즈 완료인가?", "릴리즈 완료후 harbor 미러", "이미지 및 차트 미러링", "전환경 차트 범프", or any post-release follow-up. Not for cutting or re-cutting the release itself (use release-retrigger or rust-bump-rerelease) or chart bumps unrelated to a release (use helm-bump).
argument-hint: "[component] [version]"
license: Apache-2.0
compatibility: Requires gh or glab, crane, helm, jq, and kubectl access to a cluster for large-layer skopeo Jobs; site values in ~/.zshrc.local
metadata:
  version: "1.1.0"
  category: action
  related: release-retrigger rust-bump-rerelease helm-bump git-ship
allowed-tools: Bash(gh *) Bash(glab *) Bash(crane *) Bash(helm show *) Bash(helm template *) Bash(jq *) Bash(git *) Read Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Release Promote

Carry a release from "version published" to "running config points at it".

## Site Values

Read from `~/.zshrc.local` (untracked); ask once if unset.

| Variable | Meaning | Example |
|----------|---------|---------|
| `MIRROR_REGISTRY` | Internal registry host | `registry.example.com` |
| `MIRROR_IMAGE_PATH` | Image project path | `devops` |
| `MIRROR_CHART_PATH` | Chart project path | `charts` |
| `GITOPS_REPO` | Local path of the GitOps repo with consumer charts | `~/github/org/gitops` |

## Stages

Run only the stages the request names; "전부"/"이후 단계 모두" means all three, in order. Each stage gates the next.

| Stage | Done when |
|-------|-----------|
| Status | Workflow run for the version commit is found (`gh run list` / `glab ci list`) with all jobs `success`, or reported as gone when run history is purged. Image tag and chart version both exist in the source registry |
| Mirror | Destination digest equals source digest for image and chart |
| Bump | Every environment's consumer chart references the new version, diff limited to version lines and upstream values carry-over |

## Constraints

- Release trigger and source refs come from the repo `AGENTS.md` and the release workflow (registry, image and chart name), not the directory name or an assumed tag. Releases are not tag-based unless the repo says so
- No component given: Status covers the most recent releases, while Mirror and Bump ask once for component and version
- Status: report run URL, per-job result, and failing step log tail on failure; never retry or re-tag without being asked
- No run found (history purged, e.g. by a daily cleanup workflow): judge release state from the source registry (index digest and both platforms) and say the run history is gone. Never invent a run result or error line
- In-progress run: wait on it with a background watch, do not poll in the foreground
- Mirror copies the full multi-arch index (`linux/amd64` + `linux/arm64`); never pass `--platform` to the copy. Measure layer size per platform with `crane manifest --platform`
- Mirror with `crane copy`; if any layer exceeds about 200 MB or local copy fails, run a short-lived skopeo Job inside a cluster with a minimal registry auth Secret, then delete the Job and Secret
- Charts are OCI artifacts copied the same way to `$MIRROR_REGISTRY/$MIRROR_CHART_PATH/<chart>:<version>`
- Internal docs, commits, and MRs about the mirror never mention the public source registry or personal namespace
- Bump follows the `helm-bump` skill. A wrapper chart's own `version` stays unchanged when only the upstream dependency moves
- Bump ships through the `git-ship` skill with the GitOps repo's branch policy. Its verification gate is this skill's Validation

## Validation

- `crane manifest <dest> | jq` media type is an OCI image index listing both platforms
- `crane digest <src>` equals `crane digest <dest>` for image and chart
- `helm template` renders for every bumped environment with the mirrored image reference
- `grep -rn "<old-version>" $GITOPS_REPO/<chart paths>` returns no stale reference in the bumped charts
- Final report: run URL or purge note, mirrored references, MR URL
