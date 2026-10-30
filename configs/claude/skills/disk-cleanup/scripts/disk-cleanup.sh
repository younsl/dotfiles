#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: disk-cleanup.sh [--dry-run] [--root DIR]

Remove every rebuildable cache, build output, unused container image and
every Rust toolchain except the rustup default. Items held by a running
process are skipped, never forced.

  --dry-run   measure with du and list what would be removed
  --root DIR  tree scanned for target, node_modules, dist (default: ~/github)

stdout: TSV rows "<action>\t<size>\t<item>\t<note>"
stderr: progress and capacity before and after
EOF
}

DRY_RUN=0
ROOT="$HOME/github"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --root)
      ROOT="${2:?--root needs a directory}"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
  shift
done

for tool in df du awk pgrep ps lsof git find; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "missing required tool: $tool" >&2
    exit 1
  }
done

TOTAL_KB=0
START_KB=0
BUSY_CWDS=""

log() { printf '%s\n' "$*" >&2; }
has() { command -v "$1" >/dev/null 2>&1; }

human() {
  awk -v k="$1" 'BEGIN {
    split("K M G T", u, " "); i = 1
    while (k >= 1024 && i < 4) { k /= 1024; i++ }
    printf "%.1f%s", k, u[i]
  }'
}

tilde() {
  case "$1" in
    "$HOME"/*) printf '%s/%s' '~' "${1#"$HOME"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

avail_kb() { df -Pk "$HOME" | awk 'NR == 2 { print $4 }'; }
size_kb() { du -sk "$@" 2>/dev/null | awk '{ s += $1 } END { print s + 0 }'; }
emit() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-}"; }

# Guard spec "x:<regex>" matches process names, "f:<regex>" full arguments.
# Only process names are printed; arguments can carry secrets.
blockers() {
  local spec=$1 pids=""
  case "$spec" in
    x:*) pids=$(pgrep -x "${spec#x:}" 2>/dev/null || true) ;;
    f:*) pids=$(pgrep -f "${spec#f:}" 2>/dev/null || true) ;;
  esac
  [ -n "$pids" ] || return 0
  ps -o comm= -p "$(printf '%s\n' "$pids" | paste -sd, -)" 2>/dev/null |
    sed 's#.*/##' | sort -u | paste -sd, -
}

freed() {
  local before=$1 label=$2 note=${3:-} kb
  kb=$(($(avail_kb) - before))
  [ "$kb" -ge 0 ] || kb=0
  emit removed "$(human "$kb")" "$label" "$note"
}

dry() {
  local label=$1 size_path=$2 kb
  if [ "$size_path" = "-" ]; then
    emit would-remove "?" "$label"
    return 0
  fi
  kb=$(size_kb "$size_path")
  TOTAL_KB=$((TOTAL_KB + kb))
  emit would-remove "$(human "$kb")" "$label"
}

remove_path() {
  local path=$1 guard=${2:-} label busy before
  [ -e "$path" ] || return 0
  label=$(tilde "$path")
  busy=$(blockers "$guard")
  if [ -n "$busy" ]; then
    emit skipped - "$label" "in use: $busy"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    dry "$label" "$path"
    return 0
  fi
  before=$(avail_kb)
  rm -rf "$path" 2>/dev/null || { chmod -R u+w "$path" 2>/dev/null && rm -rf "$path" 2>/dev/null; } || true
  if [ -e "$path" ]; then
    freed "$before" "$label" "partial: still being written"
  else
    freed "$before" "$label"
  fi
}

# run_cmd <label> <guard> <path measured in dry run, or -> <command...>
run_cmd() {
  local label=$1 guard=$2 size_path=$3 busy before
  shift 3
  busy=$(blockers "$guard")
  if [ -n "$busy" ]; then
    emit skipped - "$label" "in use: $busy"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    dry "$label" "$size_path"
    return 0
  fi
  before=$(avail_kb)
  if "$@" >/dev/null 2>&1 </dev/null; then
    freed "$before" "$label"
  else
    freed "$before" "$label" "command failed"
  fi
}

collect_busy_cwds() {
  BUSY_CWDS=$(lsof +c 0 -a -d cwd \
    -c '/^(cargo|rustc|node|go|zig|npm|npx|yarn|pnpm|bun|deno|terragrunt|terraform|tofu|java)$/' \
    -Fcn 2>/dev/null | awk '/^c/ { c = substr($0, 2) } /^n/ { print c "\t" substr($0, 2) }' || true)
}

# Prints the process names whose cwd is inside the project or between it and ROOT.
project_blockers() {
  local project=$1 name cwd hits=""
  while IFS=$'\t' read -r name cwd; do
    [ -n "$cwd" ] || continue
    case "$cwd" in
      "$project" | "$project"/*) hits="$hits$name"$'\n' ;;
      "$ROOT"/*)
        case "$project" in "$cwd"/*) hits="$hits$name"$'\n' ;; esac
        ;;
    esac
  done <<<"$BUSY_CWDS"
  [ -n "$hits" ] || return 0
  printf '%s' "$hits" | sort -u | paste -sd, -
}

eligible() {
  local dir=$1 parent name rc=0
  parent=$(dirname "$dir")
  name=$(basename "$dir")
  git -C "$parent" check-ignore -q -- "$name" 2>/dev/null || rc=$?
  case "$rc" in
    0) return 0 ;;
    1) return 1 ;;
  esac
  case "$name" in
    target) [ -f "$parent/Cargo.toml" ] ;;
    node_modules) [ -f "$parent/package.json" ] ;;
    .zig-cache | .terragrunt-cache) return 0 ;;
    *) return 1 ;;
  esac
}

clean_projects() {
  local dir busy
  [ -d "$ROOT" ] || return 0
  log "scanning $(tilde "$ROOT") for build outputs"
  collect_busy_cwds
  while IFS= read -r dir; do
    eligible "$dir" || continue
    busy=$(project_blockers "$(dirname "$dir")")
    if [ -n "$busy" ]; then
      emit skipped - "$(tilde "$dir")" "in use: $busy"
      continue
    fi
    remove_path "$dir"
  done < <(find "$ROOT" -name .git -prune -o -type d \
    \( -name target -o -name node_modules -o -name dist -o -name .zig-cache -o -name .terragrunt-cache \) \
    -print -prune 2>/dev/null | sort)
}

clean_rust() {
  local home keep tc
  has rustup || return 0
  home=${RUSTUP_HOME:-$HOME/.rustup}
  keep=$(rustup default 2>/dev/null | awk '{ print $1 }')
  if [ -z "$keep" ]; then
    emit skipped - "rust toolchains" "no rustup default set"
  else
    while IFS= read -r tc; do
      [ -n "$tc" ] && [ "$tc" != "$keep" ] || continue
      run_cmd "rust toolchain $tc" "f:/toolchains/$tc/" "$home/toolchains/$tc" rustup toolchain uninstall "$tc"
    done < <(rustup toolchain list 2>/dev/null | awk '{ print $1 }')
  fi
  remove_path "$home/downloads" "x:rustup|cargo|rustc"
  remove_path "$home/tmp" "x:rustup|cargo|rustc"
  local cargo_home=${CARGO_HOME:-$HOME/.cargo}
  remove_path "$cargo_home/registry/cache" "x:cargo|rustc"
  remove_path "$cargo_home/registry/src" "x:cargo|rustc"
  remove_path "$cargo_home/registry/index" "x:cargo|rustc"
  remove_path "$cargo_home/git" "x:cargo|rustc"
}

clean_go() {
  if has go; then
    run_cmd "go build, test and fuzz cache" "x:go" "$(go env GOCACHE 2>/dev/null)" go clean -cache -testcache -fuzzcache
    local modcache
    modcache=$(go env GOMODCACHE 2>/dev/null)
    [ -d "$modcache" ] && run_cmd "go module cache" "x:go" "$modcache" go clean -modcache
  fi
  remove_path "$HOME/Library/Caches/gopls" "x:gopls"
  remove_path "$HOME/.cache/gopls" "x:gopls"
  remove_path "$HOME/Library/Caches/golangci-lint" "x:golangci-lint"
  remove_path "$HOME/.cache/golangci-lint" "x:golangci-lint"
}

clean_js() {
  if has npm && [ -d "$HOME/.npm/_cacache" ]; then
    run_cmd "npm cache" "x:npm|npx" "$HOME/.npm/_cacache" npm cache clean --force
  fi
  remove_path "$HOME/.npm/_npx" "f:$HOME/.npm/_npx"
  remove_path "$HOME/Library/Caches/Yarn" "x:yarn"
  remove_path "$HOME/.cache/yarn" "x:yarn"
  remove_path "$HOME/Library/pnpm/store" "x:pnpm"
  remove_path "$HOME/.local/share/pnpm/store" "x:pnpm"
  remove_path "$HOME/Library/Caches/pnpm" "x:pnpm"
  remove_path "$HOME/.bun/install/cache" "x:bun"
  remove_path "$HOME/Library/Caches/node-gyp" "x:node-gyp|npm"
  remove_path "$HOME/.cache/node-gyp" "x:node-gyp|npm"
}

stale_buckets() {
  local entry
  for entry in "$1"/*-v[0-9]*; do
    [ -d "$entry" ] && printf '%s\n' "${entry##*/}"
  done | awk '
    match($0, /-v[0-9]+$/) {
      n[NR] = substr($0, 1, RSTART - 1); v[NR] = substr($0, RSTART + 2) + 0; e[NR] = $0
      if (v[NR] > max[n[NR]]) max[n[NR]] = v[NR]
    }
    END { for (i in e) if (v[i] < max[n[i]]) print e[i] }'
}

clean_python() {
  local dir busy bucket
  if has uv && dir=$(uv cache dir 2>/dev/null) && [ -d "$dir" ]; then
    busy=$(blockers "x:uv|uvx")
    if [ -z "$busy" ]; then
      busy=$(blockers "f:$dir")
    fi
    if [ -n "$busy" ]; then
      while IFS= read -r bucket; do
        remove_path "$dir/$bucket"
      done < <(stale_buckets "$dir" | sort)
      emit skipped - "$(tilde "$dir") (current buckets)" "in use: $busy"
    else
      run_cmd "uv cache" "" "$dir" uv cache clean
    fi
  fi
  remove_path "$HOME/Library/Caches/pip" "x:pip|pip3"
  remove_path "$HOME/.cache/pip" "x:pip|pip3"
  remove_path "$HOME/.cache/pre-commit" "x:pre-commit"
}

clean_infra() {
  remove_path "$HOME/Library/Caches/terragrunt" "x:terragrunt|terraform|tofu"
  remove_path "$HOME/.terraform.d/plugin-cache" "x:terragrunt|terraform|tofu"
  remove_path "$HOME/Library/Caches/helm" "x:helm"
  remove_path "$HOME/.cache/helm" "x:helm"
  remove_path "$HOME/Library/Caches/trivy" "x:trivy"
  remove_path "$HOME/.cache/trivy" "x:trivy"
}

clean_jvm() {
  remove_path "$HOME/.gradle/caches" "f:GradleDaemon|GradleWrapperMain"
  remove_path "$HOME/.gradle/wrapper/dists" "f:GradleDaemon|GradleWrapperMain"
  remove_path "$HOME/.m2/repository" "f:plexus-classworlds"
}

clean_runtimes() {
  remove_path "$HOME/Library/Developer/Xcode/DerivedData" "x:Xcode|xcodebuild"
  remove_path "$HOME/.cache/huggingface" "f:huggingface|transformers|whisper"
  remove_path "$HOME/.cache/whisper" "f:whisper"
  remove_path "$HOME/.cache/torch" "f:torch"
  remove_path "$HOME/Library/Caches/ms-playwright" "f:ms-playwright"
  remove_path "$HOME/.cache/ms-playwright" "f:ms-playwright"
  remove_path "$HOME/.cache/puppeteer" "f:puppeteer"
  remove_path "$HOME/Library/Caches/Cypress" "x:Cypress"
  remove_path "$HOME/.cache/Cypress" "x:Cypress"
}

clean_packages() {
  if has brew; then
    export HOMEBREW_NO_AUTO_UPDATE=1
    run_cmd "homebrew downloads and old kegs" "f:Library/Homebrew/brew.rb" "$(brew --cache)" brew cleanup --prune=all -s
    run_cmd "homebrew unused dependencies" "f:Library/Homebrew/brew.rb" - brew autoremove
  fi
  if has mise; then
    run_cmd "mise unused tool versions" "" - mise prune --yes
    run_cmd "mise cache" "" "$(mise cache path 2>/dev/null || echo -)" mise cache clear
  fi
}

podman_reclaimable_kb() {
  podman system df --format '{{.Type}}\t{{.Reclaimable}}' 2>/dev/null | awk -F'\t' '
    $1 == "Images" {
      split($2, a, " "); s = a[1]; m = 1
      if (s ~ /kB$/) m = 1; else if (s ~ /MB$/) m = 1000; else if (s ~ /GB$/) m = 1000000; else if (s ~ /TB$/) m = 1000000000; else m = 0.001
      gsub(/[A-Za-z]+$/, "", s); printf "%d\n", s * m
    }'
}

clean_podman() {
  local busy before kb
  has podman || return 0
  if ! podman info >/dev/null 2>&1; then
    emit skipped - "podman images" "podman not reachable"
    return 0
  fi
  busy=$(blockers "f:podman (build|buildx)|buildah")
  if [ -n "$busy" ]; then
    emit skipped - "podman images" "in use: $busy"
    return 0
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    kb=$(podman_reclaimable_kb)
    kb=${kb:-0}
    TOTAL_KB=$((TOTAL_KB + kb))
    emit would-remove "$(human "$kb")" "podman unused images and build cache"
    return 0
  fi
  before=$(avail_kb)
  podman image prune -af --build-cache >/dev/null 2>&1 </dev/null || true
  if [ "$(uname -s)" = Darwin ]; then
    podman machine ssh sudo fstrim -av >/dev/null 2>&1 </dev/null || true
  fi
  freed "$before" "podman unused images and build cache"
}

capacity() {
  df -h "$HOME" | awk -v tag="$1" 'NR == 2 { printf "%-6s used %s  avail %s  capacity %s\n", tag, $3, $4, $5 }' >&2
}

main() {
  START_KB=$(avail_kb)
  capacity before
  clean_projects
  clean_rust
  clean_go
  clean_js
  clean_python
  clean_infra
  clean_jvm
  clean_runtimes
  clean_packages
  clean_podman
  if [ "$DRY_RUN" -eq 1 ]; then
    emit total "$(human "$TOTAL_KB")" "would remove" "dry run"
  else
    local kb=$(($(avail_kb) - START_KB))
    [ "$kb" -ge 0 ] || kb=0
    emit total "$(human "$kb")" "reclaimed"
    capacity after
  fi
}

main
