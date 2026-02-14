# Claude Code Peasant Hooks

<img src="https://static.wikia.nocookie.net/wowpedia/images/b/bc/BTNPeasant.png" width="48" alt="Peasant">

Warcraft 3 Peasant voice hooks for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on macOS.

## Sound Files

| Hook Event | File | Voice Line |
|---|---|---|
| `SessionStart` | [PeasantReady1.wav](sounds/PeasantReady1.wav) | "Ready to work" |
| `UserPromptSubmit` | [PeasantYes3.wav](sounds/PeasantYes3.wav) | "All right" |
| `Notification` | [PeasantWhat3.wav](sounds/PeasantWhat3.wav) | "More work?" |
| `Stop` | [PeasantYes4.wav](sounds/PeasantYes4.wav) | "Off I go, then!" |

Sound files are downloaded as ogg from the CDN, then converted to wav via `afconvert` to prevent `afplay` audio clipping.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/younsl/dotfiles/main/configs/claude/hooks/setup.sh | bash
```

Requires macOS, `curl`, `jq`, `afplay`, and `afconvert`. All are pre-installed on macOS except `jq` (`brew install jq`).

## Attribution

Sound files are from **Warcraft III: Reign of Chaos** by Blizzard Entertainment.

- Source: [Wowhead Sound Database](https://www.wowhead.com/sounds/name:peasant)
- Copyright: Blizzard Entertainment, Inc.
- Usage: Personal, non-commercial use only

These sound files are the property of Blizzard Entertainment and are used here for personal convenience. All rights belong to their respective owners.
