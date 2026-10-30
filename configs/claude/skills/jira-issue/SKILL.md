---
name: jira-issue
description: Create, fill, link, and close Jira work items with the team four-section issue template via acli and ADF, estimating story points from effort.
when_to_use: Requests such as "<PROJECT>- 이슈 발행", "이 작업에 대한 이슈 만들고 SP 0.25 할당", "[결과] 섹션 작성", "완료처리", "진행중으로 표시", "에픽 연결", "유사 이슈 링크", or any request to record the current work, MR, or commit in Jira. Not for commits, pushes, or MRs (use git-ship) or prose rules outside Jira fields (use writing-style).
argument-hint: "[issue-key] [SP]"
license: Apache-2.0
compatibility: Requires acli authenticated to Jira and site values in ~/.zshrc.local; mcp-atlassian optional for web links and transition names
metadata:
  version: "1.1.0"
  category: action
  related: writing-style git-ship
allowed-tools: Bash(acli *) Bash(echo *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(glab mr view *) Read Write Grep mcp__mcp-atlassian__jira_get_transitions
user-invocable: true
disable-model-invocation: false
---

# Jira Issue

## Site Values

Site-specific values live in `~/.zshrc.local` (untracked), never in this file. Read them with `echo $VAR`; ask for all unset values in one question.

| Variable | Meaning | Example |
|----------|---------|---------|
| `JIRA_SITE` | Site host for browse URLs `https://$JIRA_SITE/browse/KEY` | `example.atlassian.net` |
| `JIRA_PROJECT` | Project key | `OPS` |
| `JIRA_ISSUE_TYPE` | Default work item type (case sensitive) | `Task` |
| `JIRA_PATCH_ISSUE_TYPE` | Type for patch/upgrade work | `Patch` |
| `JIRA_SP_FIELD` | Story point custom field id (required on create) | `customfield_10000` |
| `JIRA_ASSIGNEE` | Assignee email (`@me` resolves wrongly) | `user@example.com` |
| `JIRA_DEFAULT_EPIC` | Epic key for routine operational work | `OPS-100` |

## Story Points

SP 1 equals one 8-hour workday. Use the SP the request names; otherwise estimate from the actual effort (session length, diff size, MR count) and state the hours and estimate in the report. Estimated hours pick the row, and the examples are typical cases, not overrides.

| SP | Effort |
|----|--------|
| 0.125 | 1 hour, one-line config or version bump |
| 0.25 | 2 hours, single chart or small fix with verification |
| 0.5 | Half day, feature in one repo or multi-environment rollout |
| 1 | Full day, multi-repo change or design plus implementation |
| 2+ | Multiple days; suggest splitting into separate items |

## Output Requirements

- Title: plain text, no square brackets; patch or upgrade titles append the purpose in parentheses, e.g. `alloy chart 1.2.0 upgrade (CVE response)`
- Body sections, in order, as literal bracket headers: `[문제점 & 작업배경]`, `[작업 후 기대효과]`, `[작업 내용]`, `[결과]`
- `[결과]` stays empty at creation; fill it only when asked or when closing, from the actual MR, commits, or measurements
- Each section: single-level bullets, short sentences; no nested bullets
- Source material: the request text, current diff, MR, or pasted text; never invent numbers
- Title and body prose follow writing-style, and never contain github.com URLs in title or body
- Upper-case hyphen-number tokens that are not issue keys (`UTF-8`, `A2A-1`, `CVE-2025-1234`) are written as `utf-8`, `A2A1`, `cve-2025-1234` to avoid auto-linking
- Report the issue key, full browse URL, type, SP, epic, and status

## Tooling Reference

| Task | Command / rule |
|------|----------------|
| Create | `acli jira workitem create --from-json <file>`; keys `projectKey`, `type`, `summary`, `assignee`, `description` (ADF), `additionalAttributes.<SP field>`, `parentIssueId` (epic), `labels` |
| Edit body | `acli jira workitem edit --from-json <file> --yes` with `{"issues":["KEY"],"description":{ADF}}`, which replaces the whole body, so rebuild it from `view KEY --fields description --json` keeping the other sections; without `--yes` it hangs |
| Status | `acli jira workitem transition --key KEY --status "<exact status name>" --yes`; take the name from MCP `jira_get_transitions` (`view` shows only the current status), or ask when MCP is unavailable, never guess |
| Assign | `acli jira workitem assign --key KEY --assignee $JIRA_ASSIGNEE` |
| Blocks link | `acli jira workitem link create --out <blocked> --in <blocker> --type Blocks --yes`; the success message prints the pair reversed |
| Web link | MCP `jira_create_remote_issue_link` (acli has none) |
| Similar-issue link | `acli jira workitem link create --out KEY --in OTHER --type Relates --yes`, type names from `acli jira workitem link type` |

- Description is always ADF JSON written to a scratchpad file; markdown is stored as raw text
- Bracket headers are plain ADF text nodes in paragraphs; MCP markdown paths strip the brackets
- Links inside ADF use a `link` mark on the keyword text, never a raw URL

## Validation

- `acli jira workitem view KEY --fields description --json` shows the four bracket headers as text nodes
- SP, assignee, and epic are set on the created item
- A Blocks link reads `blocks <blocked>` on the blocker in `acli jira workitem link list --key <blocker> --json`, not just in the create message
