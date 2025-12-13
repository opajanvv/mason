#!/bin/sh
# install_all.sh - Main entry point for Phoenix bootstrap system
# Orchestrates the installation process for workstation setup

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Source helpers
. "$SCRIPTS_DIR/helpers.sh"

FORCE=false
OFFLINE=false
HOST=""

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        --offline)
            OFFLINE=true
            FORCE=true  # offline implies force (skip update check)
            shift
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        *)
            die "Unknown option: $1. Usage: $0 [-f|--force] [--offline] [--host <hostname>]"
            ;;
    esac
done

# Detect hostname
if [ -z "$HOST" ]; then
    HOST=$(hostname)
fi

log "Detected hostname: $HOST"

# Check for updates if repo is a git checkout (unless offline mode)
HAS_UPDATES=false
IS_GIT_REPO=false
if [ -d "$SCRIPT_DIR/.git" ]; then
    IS_GIT_REPO=true
    cd "$SCRIPT_DIR"

    if [ "$OFFLINE" = "true" ]; then
        log "Offline mode: skipping git fetch/pull"
    else
        # Check if there are updates before pulling
        git fetch -q || true
        current_head=$(git rev-parse HEAD || echo "")
        remote_head=$(git rev-parse @{u} || echo "")

        if [ -n "$current_head" ] && [ -n "$remote_head" ] && [ "$current_head" != "$remote_head" ]; then
            HAS_UPDATES=true
            log "Pulling latest changes from git repository..."
            git pull || warn "Failed to pull updates, continuing anyway"
        else
            log "Repository is already up to date"
        fi
    fi
fi

# Exit early if no updates and not forced (only for git repos)
if [ "$IS_GIT_REPO" = "true" ] && [ "$HAS_UPDATES" = "false" ] && [ "$FORCE" = "false" ]; then
    log "No updates found. Use -f or --force to re-apply everything anyway."
    exit 0
fi

# Run installation scripts in order
log "Starting installation process..."

# 1. Uninstall packages
log "Step 1/4: Uninstalling packages..."
"$SCRIPTS_DIR/uninstall_packages.sh" || die "Packages uninstallation failed"

# 2. Install packages
log "Step 2/4: Installing packages..."
"$SCRIPTS_DIR/install_packages.sh" || die "Packages installation failed"

# 3. Install dotfiles
log "Step 3/4: Installing dotfiles..."
"$SCRIPTS_DIR/install_dotfiles.sh" || die "Dotfiles installation failed"

# 4. Install Hyprland overrides (host-specific)
log "Step 4/4: Installing Hyprland overrides..."
"$SCRIPTS_DIR/install_overrides.sh" --host "$HOST" || die "Overrides installation failed"

log "Installation complete!"

