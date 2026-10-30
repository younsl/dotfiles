#!/bin/bash
set -euo pipefail

readonly LABEL=local.kavd-watchdog
readonly BIN_DEST=/usr/local/libexec/kavd-watchdog
readonly PLIST_DEST=/Library/LaunchDaemons/${LABEL}.plist
readonly LEGACY_PATHS=(/usr/local/libexec/kavd-watchdog.sh /var/db/kavd-watchdog)
SRC_DIR=$(cd "$(dirname "$0")" && pwd)
readonly SRC_DIR
readonly BIN_SRC=${SRC_DIR}/target/release/kavd-watchdog

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--uninstall]

Install or remove the ${LABEL} LaunchDaemon. Must run as root.
Build first with: make build
EOF
}

log() {
  printf '%s\n' "$*" >&2
}

assert_root_only_path() {
  local dir=$1 owner mode
  while :; do
    read -r owner mode < <(stat -f '%u %Lp' "$dir")
    if [[ "$owner" -ne 0 ]] || (( 8#$mode & 8#022 )); then
      log "error: ${dir} must be owned by root and not group or world writable (owner uid ${owner}, mode ${mode})"
      exit 1
    fi
    [[ "$dir" == / ]] && break
    dir=$(dirname "$dir")
  done
}

remove_legacy() {
  rm -rf "${LEGACY_PATHS[@]}"
}

uninstall() {
  launchctl bootout "system/${LABEL}" 2>/dev/null || true
  rm -f "$PLIST_DEST" "$BIN_DEST"
  remove_legacy
  log "removed ${LABEL}"
}

install_daemon() {
  if [[ ! -x "$BIN_SRC" ]]; then
    log "error: ${BIN_SRC} not found, run make build first"
    exit 1
  fi

  install -d -o root -g wheel -m 755 "$(dirname "$BIN_DEST")"
  assert_root_only_path "$(dirname "$BIN_DEST")"
  assert_root_only_path "$(dirname "$PLIST_DEST")"
  install -o root -g wheel -m 755 "$BIN_SRC" "$BIN_DEST"
  install -o root -g wheel -m 644 "${SRC_DIR}/${LABEL}.plist" "$PLIST_DEST"
  plutil -lint "$PLIST_DEST" >&2
  launchctl bootout "system/${LABEL}" 2>/dev/null || true
  remove_legacy
  launchctl bootstrap system "$PLIST_DEST"
  log "installed ${LABEL}"
}

main() {
  if [[ "$EUID" -ne 0 ]]; then
    log "error: must run as root"
    exit 1
  fi

  case "${1:-}" in
    "") install_daemon ;;
    --uninstall) uninstall ;;
    -h|--help) usage ;;
    *) usage; exit 2 ;;
  esac
}

main "$@"
