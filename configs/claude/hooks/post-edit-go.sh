#!/usr/bin/env bash
#
# Script: post-edit-go.sh
# Description: Run gofmt on .go files and go fix on their package after Edit/Write
#

set -euo pipefail

file=$(cat | jq -r '.tool_input.file_path // empty')
[[ "$file" == *.go && -f "$file" ]] || exit 0

gofmt -w "$file" 2>/dev/null || true

dir=$(cd "$(dirname "$file")" && pwd)
mod="$dir"
while [[ "$mod" != "/" && ! -f "$mod/go.mod" ]]; do
  mod=$(dirname "$mod")
done
[[ -f "$mod/go.mod" ]] || exit 0

if [[ "$dir" == "$mod" ]]; then
  pkg="."
else
  pkg="./${dir#"$mod"/}"
fi

(cd "$mod" && go fix "$pkg" >/dev/null 2>&1) || true
exit 0
