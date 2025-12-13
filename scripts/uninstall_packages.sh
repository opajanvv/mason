#!/bin/sh
# uninstall_packages.sh - Uninstall packages from uninstall.txt

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source helpers
. "$SCRIPT_DIR/helpers.sh"

UNINSTALL_FILE="$REPO_ROOT/uninstall.txt"

# Function to read packages from a file
read_packages() {
    file="$1"
    if [ ! -f "$file" ]; then
        return 0
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        case "$line" in
            \#*|"") continue ;;
        esac

        # Only include package if it's actually installed
        if yay -Q "$line" >/dev/null 2>&1; then
            echo "$line"
        fi
    done < "$file"
}

# Read packages to uninstall
log "Reading packages to uninstall from $UNINSTALL_FILE"
packages=$(read_packages "$UNINSTALL_FILE" | tr '\n' ' ')

if [ -z "$packages" ]; then
    log "No packages to uninstall"
    exit 0
fi

# Uninstall packages with their unused dependencies
log "Uninstalling packages with yay: $packages"
yay -Rns --noconfirm $packages || die "Failed to uninstall packages"

log "Packages uninstalled successfully"
