---
name: release-retrigger
description: Re-trigger a release by committing changes, deleting and re-pushing a semver tag. Use when re-releasing, re-tagging, cycling a release tag, or re-triggering a CI/CD release pipeline.
---

# Release Retrigger

Re-trigger a release pipeline by cycling a semver tag with updated changes.

## Prerequisites

- `gh` CLI authenticated
- Push access to the repository and its packages

## Constraints

- User MUST specify the version — never assume or auto-increment
- Tag format derived from the repo's CLAUDE.md release/workflow section (e.g., `kuo/0.2.0`, `backstage/1.48.5-1`, `grafana-dashboards/charts/1.0.0`)
- Commit message follows the repo's CLAUDE.md convention
- Push to the current branch only — never force-push
- No confirmation pauses — proceed through all phases continuously once invoked
- Phase 2: suppress errors with `2>/dev/null`; silently skip resources that don't exist

## Workflow

### Phase 1: Commit and Push

- Stage and commit current changes (skip entire Phase 1 if working tree is clean)
- Push commits to current branch
- If push is denied by permissions, ask user to run the push command manually, then continue to Phase 2

### Phase 2: Cleanup

Run all cleanup steps in parallel — they are independent:

- Delete local tag: `git tag -d <tag> 2>/dev/null`
- Delete remote tag: `git push origin --delete <tag> 2>/dev/null`
- Delete GitHub Release if exists: `gh release delete <tag> --yes --cleanup-tag 2>/dev/null`
- Delete GHCR container image tag if exists (see GHCR reference below)

### Phase 3: Re-tag and Push

- Create tag on HEAD and push: `git tag <tag> && git push origin <tag>`

## GHCR Image Deletion Reference

Derive the GHCR package name from the tag prefix. Use a one-liner with `--jq` to find and delete:

| Tag format | Package name | Image tag |
|---|---|---|
| `kuo/0.2.0` | `kuo` | `0.2.0` |
| `backstage/1.48.5-1` | `backstage` | `1.48.5-1` |
| `grafana-dashboards/charts/1.2.0` | `charts%2Fgrafana-dashboards` | `1.2.0` |

```bash
# One-liner: find version ID by image tag and delete
VERSION_ID=$(gh api /user/packages/container/<package>/versions \
  --jq '.[] | select(.metadata.container.tags[] == "<image_tag>") | .id' 2>/dev/null) \
  && [ -n "$VERSION_ID" ] \
  && gh api -X DELETE /user/packages/container/<package>/versions/$VERSION_ID
```

For org-owned packages, replace `/user/` with `/orgs/<org>/`.

## Validation

Run all checks in parallel:

- `git tag -l <tag>` — tag exists locally
- `git ls-remote --tags origin <tag>` — tag exists on remote
