---
name: bash-generator
description: Generate production-ready Bash scripts. Use when creating automation, deployment, CI/CD helper, or system administration shell scripts.
---

# Bash Script Generator

Generate production-ready, portable, and safe Bash scripts.

## Output Requirements

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail` with `IFS=$'\n\t'`
- All variables double-quoted (`"$variable"`)
- Constants declared with `readonly`
- Function-scoped variables use `local`
- Code organized into functions, not top-level imperative blocks
- Cleanup via `trap` on EXIT
- Required commands checked with `command -v` before use
- Required arguments and file existence validated before use
- Log output to stderr (`>&2`), not stdout
- `usage()` function for `--help` flag
- Default values via parameter expansion: `"${1:-default}"`

## Script Header

```bash
#!/usr/bin/env bash
#
# Script: script-name.sh
# Description: Brief description
# Usage: ./script-name.sh [options] <arguments>
#

set -euo pipefail
IFS=$'\n\t'
```

## Quality Attributes

- **Portable**: `#!/usr/bin/env bash`, avoid unnecessary bashisms
- **Safe**: No unquoted variables, no `eval`, no glob expansion surprises
- **Debuggable**: Support `--verbose` and `--dry-run` flags
- **Idempotent**: Safe to re-run

## Argument Parsing

Use `while [[ $# -gt 0 ]]; case ... esac; done` pattern with `--`, `-*`, and positional argument handling.

## Validation

Generated scripts should pass:

- `bash -n script.sh` (syntax check)
- `shellcheck script.sh` (static analysis)
