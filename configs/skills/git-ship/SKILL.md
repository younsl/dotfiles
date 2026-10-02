---
name: git-ship
description: Commit, push, branch, and open or update a GitLab MR or GitHub PR in one pass, following repo branch policy and the user's MR body conventions.
when_to_use: Short ship requests such as "커밋 푸시", "커밋만", "별도 브랜치에 커밋 푸시", "MR 생성", "MR 제출", "커밋 푸시후 MR 생성", "MR 업데이트", "MR 분량 30%로 축소", "commit push". Not for tag-based re-releases (use release-retrigger).
argument-hint: "[context for 진행배경]"
license: Apache-2.0
compatibility: Requires git plus glab (GitLab) or gh (GitHub), authenticated
metadata:
  version: "1.0.0"
  category: action
  related: done-check writing-style release-retrigger
allowed-tools: Bash(git *) Bash(glab *) Bash(gh *) Read Edit Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Git Ship

Turn a one-line ship request into commit, push, and MR/PR with no follow-up questions.

## Request Mapping

| Request | Scope |
|---------|-------|
| 커밋 / 커밋만 | Commit only |
| 커밋 푸시 / 푸시 | Commit + push to current branch |
| 별도 브랜치에 커밋 푸시 / (별도 브랜치에서 진행) | New branch from default branch + commit + push |
| MR 생성 / MR 제출 / MR 올려 | Above + open MR (create a branch first if on default branch) |
| MR 업데이트 / MR 내용 업데이트 | Rewrite description of the open MR for this branch |
| MR 분량 N%로 축소 | Rewrite description to about N% of current length, keep sections |

## Constraints

- Repo rules win: read the repo `AGENTS.md`/`CLAUDE.md` and project memory for branch policy (direct push vs MR) and commit format before anything else
- Stage explicit paths of the current task only; never `git add -A`, never sweep unrelated changes or other people's edits
- Commit format: repo convention, else Conventional Commits `type(scope): subject`; subject language matches recent `git log`
- Commit wording distinguishes a fix for something missing from a new addition
- No `Co-Authored-By`, Claude session trailers, or tool attribution in commits or MR bodies
- github.com remote: commit with `-s` (DCO). GPG signing is global
- Branch name: `<type>/<short-kebab-topic>` (`feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, `bump/`)
- Never force-push a shared branch; never push to the default branch when repo policy requires MR
- Push denied by permissions: print the exact command for the user, then continue with the remaining steps
- Run the verification gate from the `done-check` skill before pushing code changes; skip for docs-only or toolchain-only bumps

## MR / PR Body

- GitLab remote uses `glab mr create --remove-source-branch --yes` targeting the default branch; GitHub uses `gh pr create`
- Title: conventional prefix kept, rest in the language of recent MR titles (Korean for internal GitLab repos)
- Sections in order: `## 진행배경`, `## 변경사항`, `## 기타사항`. Add `## 테스트 결과` only for substantial verification output, `## 로드맵` only for future plans
- Each section 1 to 3 bullets; why over what; no file-by-file or permission-by-permission listing
- If the user states context in the request ("~하는 작업이야", "기타사항에 ~ 언급"), it goes verbatim in meaning into 진행배경 or 기타사항
- Derived MR: 진행배경 opens with the triggering MR link and why it ships now
- Links as `[keyword](url)`; other-repo MR references as full URL links, never bare `!123`
- Writing rules from the `writing-style` skill apply (no em dash, no middle dot, no horizontal rules)

## MR Update Rules

- Fetch the current remote description first and merge; preserve user-added screenshots and paragraphs
- After any push to a branch with an open MR, sync the description if the change alters what it claims; skip for pure formatting commits
- Shrink requests: drop detail, keep the three core sections, never drop user-written lines

## Validation

- `git status --short` shows no leftover task files; unrelated files untouched
- `git log -1 --format=%B` matches convention, no trailers besides `Signed-off-by`
- `git rev-parse @{u}` equals `HEAD` after push
- Final report: branch, commit subject, full MR/PR URL
