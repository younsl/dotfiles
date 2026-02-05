# Bash Script Generator

Generate production-ready, portable, and safe Bash scripts.

## When to Use
- Creating automation scripts
- Writing deployment scripts
- Building CI/CD helper scripts
- System administration tasks

## Core Rules

### 1. Use Strict Mode

Always start with `set -euo pipefail`.

### 2. Quote All Variables

Use `"$variable"` to prevent word splitting.

### 3. Use Functions

Organize code into functions with `local` variables.

### 4. Add Error Handling

Use `trap` for cleanup and meaningful error messages.

### 5. Validate Inputs

Check required arguments and file existence before use.

## Script Template

```bash
#!/usr/bin/env bash
#
# Script: script-name.sh
# Description: Brief description of what the script does
# Usage: ./script-name.sh [options] <arguments>
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#   -d, --dry-run  Show what would be done without executing
#

set -euo pipefail
IFS=$'\n\t'

# =============================================================================
# Configuration
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Default values
VERBOSE=false
DRY_RUN=false

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    echo "[INFO] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# =============================================================================
# Helper Functions
# =============================================================================

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [options] <arguments>

Description:
    Brief description of what the script does.

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -d, --dry-run   Show what would be done without executing

Examples:
    $SCRIPT_NAME --verbose input.txt
    $SCRIPT_NAME --dry-run --verbose input.txt

EOF
    exit 0
}

die() {
    log_error "$*"
    exit 1
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        die "Required command not found: $cmd"
    fi
}

confirm() {
    local message="${1:-Are you sure?}"
    read -r -p "$message [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# =============================================================================
# Main Functions
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    # Store remaining arguments
    ARGS=("$@")
}

validate_args() {
    # Add validation logic here
    if [[ ${#ARGS[@]} -lt 1 ]]; then
        die "Missing required argument. Use --help for usage."
    fi
}

main() {
    parse_args "$@"
    validate_args

    log_info "Starting $SCRIPT_NAME"
    log_debug "Verbose mode enabled"

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Dry-run mode - no changes will be made"
    fi

    # Main script logic here
    for arg in "${ARGS[@]}"; do
        log_info "Processing: $arg"

        if [[ "$DRY_RUN" == false ]]; then
            # Actual execution
            :
        fi
    done

    log_info "Completed successfully"
}

# =============================================================================
# Entry Point
# =============================================================================

main "$@"
```

## Best Practices

### Safety Options
```bash
# Always use at the start of scripts
set -euo pipefail

# -e: Exit on error
# -u: Error on undefined variables
# -o pipefail: Exit on pipe failures
```

### Variable Handling
```bash
# Always quote variables
echo "$variable"

# Use default values
name="${1:-default_name}"

# Use readonly for constants
readonly CONFIG_FILE="/etc/app/config.yaml"

# Use local in functions
my_function() {
    local result=""
    result=$(some_command)
    echo "$result"
}
```

### Error Handling
```bash
# Trap for cleanup
cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

# Check command existence
command -v kubectl &> /dev/null || die "kubectl not found"

# Check file existence
[[ -f "$config_file" ]] || die "Config file not found: $config_file"
```

### Input Validation
```bash
# Validate required arguments
[[ -n "${1:-}" ]] || die "First argument is required"

# Validate file exists
[[ -f "$input_file" ]] || die "File not found: $input_file"

# Validate directory exists
[[ -d "$output_dir" ]] || mkdir -p "$output_dir"

# Validate numeric input
[[ "$count" =~ ^[0-9]+$ ]] || die "Count must be a number"
```

## Common Patterns

### Process Files
```bash
while IFS= read -r line || [[ -n "$line" ]]; do
    process_line "$line"
done < "$input_file"
```

### Array Operations
```bash
# Declare array
declare -a items=("a" "b" "c")

# Iterate
for item in "${items[@]}"; do
    echo "$item"
done

# Length
echo "Count: ${#items[@]}"
```

### Temporary Files
```bash
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

echo "data" > "$TEMP_FILE"
```

### JSON with jq
```bash
# Parse JSON
name=$(echo "$json" | jq -r '.name')

# Iterate JSON array
echo "$json" | jq -c '.items[]' | while read -r item; do
    echo "$item" | jq -r '.id'
done
```

### Kubernetes Helpers
```bash
# Get pod names
kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}'

# Wait for rollout
kubectl rollout status deployment/"$deployment" -n "$namespace" --timeout=300s

# Port forward with background cleanup
kubectl port-forward svc/"$service" 8080:80 &
PF_PID=$!
trap 'kill $PF_PID 2>/dev/null' EXIT
```

## DevOps Script Examples

### Deploy Script
```bash
#!/usr/bin/env bash
set -euo pipefail

deploy() {
    local env="$1"
    local version="$2"

    log_info "Deploying version $version to $env"

    helm upgrade --install app ./charts/app \
        -n "$env" \
        --set image.tag="$version" \
        --wait \
        --timeout 5m
}
```

### Health Check Script
```bash
#!/usr/bin/env bash
set -euo pipefail

check_health() {
    local endpoint="$1"
    local max_retries=30
    local retry_interval=10

    for ((i=1; i<=max_retries; i++)); do
        if curl -sf "$endpoint/health" > /dev/null; then
            log_info "Health check passed"
            return 0
        fi
        log_warn "Attempt $i/$max_retries failed, retrying in ${retry_interval}s..."
        sleep "$retry_interval"
    done

    die "Health check failed after $max_retries attempts"
}
```

## Validation
```bash
# Syntax check
bash -n script.sh

# ShellCheck
shellcheck script.sh

# Test execution
bash -x script.sh  # Debug mode
```
