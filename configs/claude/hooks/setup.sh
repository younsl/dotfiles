#!/usr/bin/env bash
#
# Script: setup.sh
# Description: Set up Warcraft 3 Peasant voice hooks for Claude Code (macOS)
# Usage: ./setup.sh [--verbose] [--dry-run] [--help]
#

set -euo pipefail
IFS=$'\n\t'

readonly HOOKS_DIR="${HOME}/.claude/hooks"
readonly SOUNDS_DIR="${HOOKS_DIR}/sounds"
readonly SETTINGS_FILE="${HOME}/.claude/settings.json"
readonly CDN_BASE="https://wow.zamimg.com/sound-ids/live/enus"

# Parallel arrays for sound definitions
readonly SOUND_NAMES=(PeasantReady1 PeasantYes3 PeasantWhat3 PeasantYes4)
readonly SOUND_PATHS=(
  "${CDN_BASE}/38/558118/PeasantReady1.ogg"
  "${CDN_BASE}/44/558124/PeasantYes3.ogg"
  "${CDN_BASE}/47/558127/PeasantWhat3.ogg"
  "${CDN_BASE}/45/558125/PeasantYes4.ogg"
)

# Hook event → sound mapping (parallel arrays)
readonly HOOK_EVENTS=(SessionStart UserPromptSubmit Notification Stop)
readonly HOOK_SOUNDS=(PeasantReady1 PeasantYes3 PeasantWhat3 PeasantYes4)

VERBOSE=false
DRY_RUN=false

log() { printf '[INFO] %s\n' "$*" >&2; }
log_verbose() { [[ "${VERBOSE}" == true ]] && printf '[DEBUG] %s\n' "$*" >&2 || true; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [options]

Set up Warcraft 3 Peasant voice hooks for Claude Code.

Options:
  --verbose   Show detailed output
  --dry-run   Show what would be done without making changes
  --help      Show this help message

Hook events:
  SessionStart       → PeasantReady1.wav  ("Ready to work")
  UserPromptSubmit   → PeasantYes3.wav    ("All right")
  Notification       → PeasantWhat3.wav   ("More work?")
  Stop               → PeasantYes4.wav    ("Off I go, then!")
EOF
  exit 0
}

check_requirements() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This script requires macOS (uses afplay and afconvert)"
    exit 1
  fi

  for cmd in curl jq afplay afconvert; do
    if ! command -v "${cmd}" &>/dev/null; then
      log_error "Required command not found: ${cmd}"
      exit 1
    fi
  done
  log_verbose "All required commands available"
}

download_sounds() {
  mkdir -p "${SOUNDS_DIR}"
  log "Downloading Peasant sound files to ${SOUNDS_DIR}"

  local failed=0
  local converted=0
  local skipped=0
  local i
  for i in "${!SOUND_NAMES[@]}"; do
    local name="${SOUND_NAMES[${i}]}"
    local url="${SOUND_PATHS[${i}]}"
    local wav="${SOUNDS_DIR}/${name}.wav"

    if [[ -f "${wav}" ]]; then
      log_verbose "Already exists, skipping: ${name}.wav"
      ((skipped++)) || true
      continue
    fi

    if [[ "${DRY_RUN}" == true ]]; then
      log "[DRY-RUN] Would download and convert ${name}"
      continue
    fi

    local ogg="${SOUNDS_DIR}/${name}.ogg"

    log_verbose "Downloading ${name}.ogg"
    if ! curl -fsSL -o "${ogg}" "${url}"; then
      log_error "Failed to download ${name}.ogg"
      ((failed++)) || true
      continue
    fi

    if [[ ! -s "${ogg}" ]]; then
      log_error "Downloaded file is empty: ${name}.ogg"
      rm -f "${ogg}"
      ((failed++)) || true
      continue
    fi

    log_verbose "Converting ${name}.ogg → ${name}.wav"
    if ! afconvert "${ogg}" "${wav}" -d LEI16 -f WAVE; then
      log_error "Failed to convert ${name}.ogg to wav"
      rm -f "${wav}"
      ((failed++)) || true
      continue
    fi

    rm -f "${ogg}"
    ((converted++)) || true
  done

  if [[ "${failed}" -gt 0 ]]; then
    log_error "${failed} sound file(s) failed to download or convert"
    exit 1
  fi

  log "All sound files ready (${converted} converted, ${skipped} skipped)"
}

build_hooks_json() {
  local hooks_json="{}"
  local i

  for i in "${!HOOK_EVENTS[@]}"; do
    local event="${HOOK_EVENTS[${i}]}"
    local sound="${HOOK_SOUNDS[${i}]}"
    local cmd="nohup afplay ~/.claude/hooks/sounds/${sound}.wav &"
    hooks_json=$(printf '%s' "${hooks_json}" | jq \
      --arg event "${event}" \
      --arg cmd "${cmd}" \
      '.[$event] = [{"hooks": [{"type": "command", "command": $cmd}]}]')
  done

  printf '%s' "${hooks_json}"
}

update_settings() {
  log "Updating ${SETTINGS_FILE}"

  local hooks_json
  hooks_json=$(build_hooks_json)

  if [[ ! -f "${SETTINGS_FILE}" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
      log "[DRY-RUN] Would create ${SETTINGS_FILE}"
      return
    fi
    mkdir -p "$(dirname "${SETTINGS_FILE}")"
    printf '{}' > "${SETTINGS_FILE}"
  fi

  local merged
  merged=$(jq --argjson hooks "${hooks_json}" '.hooks = $hooks' "${SETTINGS_FILE}")

  if [[ "${DRY_RUN}" == true ]]; then
    log "[DRY-RUN] Would write settings:"
    printf '%s\n' "${merged}" | jq . >&2
    return
  fi

  local resolved
  resolved=$(readlink "${SETTINGS_FILE}" 2>/dev/null || printf '%s' "${SETTINGS_FILE}")
  printf '%s\n' "${merged}" | jq . > "${resolved}"
  log "Settings updated successfully"
}

verify() {
  log "Verifying setup"
  local ok=true

  for name in "${SOUND_NAMES[@]}"; do
    local dest="${SOUNDS_DIR}/${name}.wav"
    if [[ ! -s "${dest}" ]]; then
      log_error "Missing: ${dest}"
      ok=false
    else
      log_verbose "OK: ${dest} ($(wc -c < "${dest}" | tr -d ' ') bytes)"
    fi
  done

  if ! jq -e '.hooks' "${SETTINGS_FILE}" &>/dev/null; then
    log_error "hooks key missing from ${SETTINGS_FILE}"
    ok=false
  else
    log_verbose "OK: hooks configured in settings.json"
  fi

  if [[ "${ok}" == true ]]; then
    log "Setup complete. Restart Claude Code to activate hooks."
  else
    log_error "Setup completed with errors"
    exit 1
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --verbose) VERBOSE=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      --help) usage ;;
      --) shift; break ;;
      -*) log_error "Unknown option: $1"; usage ;;
      *) break ;;
    esac
  done

  check_requirements
  download_sounds
  update_settings

  if [[ "${DRY_RUN}" == false ]]; then
    verify
  fi
}

main "$@"
