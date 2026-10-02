---
name: writing-style
description: Personal writing rules for prose meant for humans, including README, docs, Confluence pages, MR and PR bodies, Jira text, commit messages, Slack announcements, UI copy, and slides.
when_to_use: Whenever drafting or editing such text, and for requests like "간결하게", "문서화해줘", "가이드 작성", "슬랙 공지 작성", "하위 페이지로 정리", "구분선 제거", "emdash 금지", "N%로 축소".
argument-hint: "[file or target]"
license: Apache-2.0
compatibility: Confluence rules assume mcp-atlassian storage-format writes
metadata:
  version: "1.0.0"
  category: style
  related: git-ship jira-issue
allowed-tools: Read Edit Write Grep Glob
user-invocable: true
disable-model-invocation: false
---

# Writing Style

## Output Requirements

- No em dash (—), en dash (–), or middle dot (·); rewrite as a sentence, comma, colon, or parentheses
- No horizontal rules (`---`, `***`) in bodies; headings separate sections. Table separators and frontmatter are exempt
- No emoji in titles or headings
- No semicolons in prose
- Bullets over tables; a table only when rows and columns are both meaningful axes
- Concise and direct: lead with the point, one idea per bullet, no filler intro or recap
- Length requests ("N%로 축소", "더 간결하게") target that ratio of the current text and keep the section skeleton
- URLs wrapped on a keyword: `[Helm docs](https://example.com)`, never raw; cross-repo MR or PR references as full URL links
- Unambiguous notation: no `4/4`-style shorthand that reads as a date; HTTP status as code plus reason (`403 Forbidden`)
- Dates only in shared documents, no clock times
- No backtick spans around plain words in prose, wiki, Slack, or UI copy; reserve them for real identifiers in markdown that renders code
- Markdown paragraphs are one line each; no hard wrapping
- Language follows the existing document; new public OSS text is English, internal team text is Korean
- Public repos never mention company names, internal hosts, or internal systems; internal docs never mention personal repos or public personal registries

## Document Structure

- Guides open with an overview stating purpose and target reader in one or two sentences
- Default order: overview, background, guide body, conclusion; table of contents for long pages
- A guide covers the single path its reader takes; alternatives collapse to one line pointing at the owning team
- User-facing how-to pages: one sentence per step plus a screenshot
- Slack announcements: three to five short lines, sentence form, link to the doc at the end

## Confluence Reference

| Need | Rule |
|------|------|
| Body format | Storage format (XHTML) directly; markdown conversion flattens nested bullets and breaks Korean particles next to code or bold |
| Centered image | `<p style="text-align: center;"><ac:image ac:align="center" ac:width="760"><ri:attachment ri:filename="x.png"/></ac:image></p>` |
| New page location | Child of the page URL the user gives; title text only |
| Diagram | PNG rendered at 2x, displayed at width 760 |

## Validation

- `grep -nP '[—–·]' <file>` returns nothing
- `grep -nE '^(-{3,}|\*{3,})$' <file>` returns only frontmatter lines
- No raw `https://` outside link syntax or code blocks
