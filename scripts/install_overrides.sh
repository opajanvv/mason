#!/bin/sh
# install_overrides.sh - Install Hyprland overrides

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source helpers
. "$SCRIPT_DIR/helpers.sh"

# Local helper: append line to file if not already present
append_if_absent() {
    file="$1"
    line="$2"

    if grep -qF "$line" "$file"; then
        log "Line already present in $file, skipping"
    else
        echo "$line" >> "$file"
        log "Appended to $file: $line"
    fi
}

HOST=""

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            die "Unknown option: $1. Usage: $0 --host <hostname>"
            ;;
    esac
done

if [ -z "$HOST" ]; then
    die "Hostname not specified. Usage: $0 --host <hostname>"
fi

# Override file paths
HOST_OVERRIDES_FILE="$REPO_ROOT/hosts/$HOST/overrides.conf"
COMMON_OVERRIDES_FILE="$REPO_ROOT/overrides.conf"
HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"

# Source common overrides first (shared across all hosts)
if [ -f "$COMMON_OVERRIDES_FILE" ] && [ -s "$COMMON_OVERRIDES_FILE" ]; then
    append_if_absent "$HYPRLAND_CONFIG" "source = $COMMON_OVERRIDES_FILE"
    log "Using common overrides"
fi

# Source host-specific overrides on top (can override common settings)
if [ -f "$HOST_OVERRIDES_FILE" ] && [ -s "$HOST_OVERRIDES_FILE" ]; then
    append_if_absent "$HYPRLAND_CONFIG" "source = $HOST_OVERRIDES_FILE"
    log "Using host-specific overrides for $HOST"
fi

log "Overrides installed successfully"

