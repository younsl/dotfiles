#!/usr/bin/env bash
#
# Script: post-edit-rs.sh
# Description: Run rustfmt on .rs files after Edit/Write
#

set -euo pipefail

file=$(cat | jq -r '.tool_input.file_path // empty')
[[ "$file" == *.rs ]] && rustfmt "$file" 2>/dev/null || true
exit 0
