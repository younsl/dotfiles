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

- Tag format: semver without `v` prefix (`1.2.3`, `0.1.0`)
- User MUST specify the tag — never assume or auto-increment
- Commit message follows the repo's CLAUDE.md convention
- Push to the current branch only — never force-push
- Phase 2: check existence first; silently skip resources that don't exist (tag, release, image)

## Workflow

### Phase 1: Commit and Push

- Stage and commit current changes (skip if working tree is clean)
- Push commits to current branch

### Phase 2: Cleanup

- Delete local tag: `git tag -d <tag>`
- Delete remote tag: `git push origin --delete <tag>`
- Delete GitHub Release if exists: `gh release delete <tag> --yes --cleanup-tag`
- Delete GHCR container image tag if exists (see GHCR reference below)

### Phase 3: Re-tag and Push

- Create tag on HEAD: `git tag <tag>`
- Push tag: `git push origin <tag>`

## GHCR Image Deletion Reference

When the argument is `<name> <tag>` (e.g., `backstage 1.48.5-1`), the tag is `<name>/<tag>`, the GHCR package name is `<name>`, and the image tag to match is `<tag>`.

Use `gh api` to find and delete the version matching the image tag.

```
# List versions for the package
gh api /user/packages/container/<package>/versions

# Delete a specific version by ID
gh api -X DELETE /user/packages/container/<package>/versions/<version_id>
```

For org-owned packages, replace `/user/` with `/orgs/<org>/`.

## Validation

After completion, verify:

- `git tag -l <tag>` — tag exists locally
- `git ls-remote --tags origin <tag>` — tag exists on remote
- `gh release view <tag>` — new release created (if CI triggers on tag push)
