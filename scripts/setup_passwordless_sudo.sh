#!/bin/sh
# setup_passwordless_sudo.sh - Configure passwordless sudo for janstrap automation
#
# This script must be run with sudo on each target machine
# Usage: sudo ./scripts/setup_passwordless_sudo.sh

set -eu

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source helpers
. "$SCRIPT_DIR/helpers.sh"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    die "This script must be run with sudo"
fi

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$(whoami)}"

if [ "$ACTUAL_USER" = "root" ]; then
    die "Cannot determine actual user. Please run with sudo, not as root directly"
fi

SUDOERS_FILE="/etc/sudoers.d/janstrap"

log "Creating sudoers file for user: $ACTUAL_USER"

# Create sudoers file
cat > "$SUDOERS_FILE" << EOF
# janstrap - Allow all commands without password for bootstrap automation
# WARNING: Less secure - allows all sudo commands without password
$ACTUAL_USER ALL=(ALL) NOPASSWD: ALL
EOF

# Set correct permissions
chmod 0440 "$SUDOERS_FILE"

log "Sudoers file created: $SUDOERS_FILE"

# Validate sudoers configuration
if visudo -c; then
    log "Sudoers configuration is valid"
    log "Passwordless sudo configured successfully for ALL commands"
else
    die "Sudoers configuration is invalid!"
fi
