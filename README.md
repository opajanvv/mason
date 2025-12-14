# JanStrap

**A simple, idempotent bootstrap system for Omarchy workstations.**

JanStrap automates the setup and maintenance of multiple workstations in a homelab environment. The goal is simple: painless installation and easy distribution of tools and settings across all machines.

> **Note:** This is a template repository. Use the "Use this template" button on GitHub to create your own independent copy.

> **Example:** See [opajanvv/mystrap](https://github.com/opajanvv/mystrap) for a working implementation with encrypted secrets, Google Drive sync, and automatic dotfile syncing.

## Credits

Inspired by and based on the YouTube video ["You installed Omarchy, Now What?"](https://www.youtube.com/watch?v=d23jFJmcaMI) by **typecraft**. Source: [typecraft-dev/omarchy-supplement](https://github.com/typecraft-dev/omarchy-supplement).

## Overview

JanStrap provides a single repository that can:
1. Bootstrap a workstation once
2. Re-apply updates any time (pull latest changes and reconcile)

The system is designed with strict idempotency: safe to re-run, no interactive prompts, and guarded edits.

## Features

- **Idempotent**: Safe to run multiple times without duplication or errors
- **Host-specific config**: Per-machine overrides for Hyprland and dotfiles
- **Stacked overrides**: Common settings plus host-specific overrides (inheritance model)
- **Post-install scripts**: Optional per-package scripts for service enablement, etc.
- **GNU Stow**: Clean dotfile management with symlinks
- **yay-based**: Uses `yay` for all package management (official repos and AUR)
- **Auto-detection**: Automatically detects hostname
- **Git-aware**: Pulls updates automatically, exits early if no changes
- **Offline mode**: Run without network using `--offline` flag
- **File cleanup**: Remove unwanted files before installation

## Repository Structure

```
janstrap/
├── install_all.sh          # Main entry point
├── packages.txt            # Packages to install
├── uninstall.txt           # Packages to remove
├── remove_files.txt        # Files to remove before installation
├── stow.txt                # Dotfiles to stow
├── overrides.conf          # Common Hyprland overrides (all hosts)
├── dotfiles/               # Common dotfiles (applied to all hosts)
│   └── waybar/
│       └── .config/waybar/
│           ├── config.jsonc
│           └── style.css
├── install/                # Post-install scripts (optional)
│   └── cronie.sh           # Example: Enable cronie service
├── hosts/
│   ├── laptop1/
│   │   ├── overrides.conf  # Host-specific Hyprland overrides
│   │   └── dotfiles/       # Host-specific dotfiles (optional)
│   └── laptop2/
│       └── overrides.conf  # Host-specific Hyprland overrides
└── scripts/
    ├── helpers.sh          # Utility functions (log, warn, die)
    ├── remove_files.sh     # Remove unwanted files
    ├── uninstall_packages.sh
    ├── install_packages.sh
    ├── install_dotfiles.sh
    ├── install_overrides.sh
    ├── install_cron.sh     # Optional: Set up automatic updates
    └── setup_passwordless_sudo.sh  # One-time sudo setup
```

## Requirements

JanStrap is designed for **Omarchy**, which comes with most requirements pre-installed:
- `yay` - Package manager for official repos and AUR (pre-installed)
- `git` - Repository cloning and updates (pre-installed)
- `stow` - Dotfile management with symlinks (add to packages.txt)

## Quick Start

**1. Use this template**

Click "Use this template" on GitHub to create your own repository.

**2. Clone your repository**

```bash
git clone <your-repo-url> janstrap
cd janstrap
```

**3. Customize**

- Edit `packages.txt` - Add your preferred packages
- Edit `dotfiles/` - Add your configuration files
- Edit `hosts/<hostname>/overrides.conf` - Set up monitor configuration

**4. Run the installer**

```bash
./install_all.sh
```

The installer will:
1. Remove unwanted files (from remove_files.txt)
2. Uninstall unwanted packages (from uninstall.txt)
3. Install all packages (from packages.txt)
4. Stow all dotfiles (from dotfiles/ and hosts/`<hostname>`/dotfiles/)
5. Apply Hyprland overrides (common + host-specific)

## Configuration Files

### packages.txt

List of packages to install, one per line. Comments start with `#`.

```
# Common packages for all workstations
stow
cronie
google-chrome
waybar
```

### remove_files.txt

Files to remove before package installation. Use `~` for home directory paths:

```
# Files to remove (one per line)
~/.local/share/applications/UnwantedApp.desktop
```

### uninstall.txt

Omarchy bloatware to remove on fresh install. These packages ship with Omarchy but aren't needed:

```
# Omarchy bloatware to remove on fresh install
omarchy-chromium    # Using google-chrome instead
typora              # Using mousepad instead
1password           # Not using password manager
```

### stow.txt

Dotfile packages to stow (correspond to directories in `dotfiles/`):

```
waybar
```

### Hyprland Overrides

JanStrap uses a **stacked override model** for Hyprland configuration:

1. **Common overrides** (`overrides.conf` at repo root) - Applied to all hosts
2. **Host-specific overrides** (`hosts/<hostname>/overrides.conf`) - Applied on top

Both files are automatically sourced by Hyprland. Host-specific settings override common settings.

**Example - hosts/laptop1/overrides.conf:**
```
# Monitor configuration for laptop1
env = GDK_SCALE,2
monitor=HDMI-A-1,1920x1080@60,-1920x0,1
monitor=eDP-1,1366x768@60,0x0,1
```

## Post-Install Scripts

Optional scripts that run after package installation. Use for enabling services, setting defaults, etc.

**Example: `install/cronie.sh`**

```bash
#!/bin/sh
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/../scripts/helpers.sh"

# Check if we can use sudo without password
if ! sudo -n true 2>/dev/null; then
    warn "Cannot enable cronie.service without sudo access"
    exit 0
fi

# Enable and start cronie
if ! systemctl is-enabled cronie.service >/dev/null 2>&1; then
    sudo systemctl enable cronie.service
fi
if ! systemctl is-active cronie.service >/dev/null 2>&1; then
    sudo systemctl start cronie.service
fi
```

**Requirements:**
- Filename must match package name: `cronie.sh` for package `cronie`
- Must be executable: `chmod +x install/cronie.sh`
- Must be idempotent: Safe to run multiple times

## Re-Applying Updates

Run `install_all.sh` again to apply updates:

```bash
./install_all.sh
```

The installer will:
- Pull latest changes from git
- Reconcile package installations
- Update dotfile symlinks
- Re-apply overrides

**Command line options:**

```bash
./install_all.sh --force    # Re-apply even if no git updates
./install_all.sh --offline  # Skip git fetch/pull (implies --force)
./install_all.sh --host X   # Override hostname detection
```

## Optional Features

### Passwordless Sudo

For unattended operation, configure passwordless sudo:

```bash
sudo ./scripts/setup_passwordless_sudo.sh
```

This creates `/etc/sudoers.d/janstrap` allowing all sudo commands without password.

### Automatic Updates via Cron

To enable automatic updates every 6 hours, uncomment the cron section in `install_all.sh`:

```bash
# OPTIONAL: Install cron job for automatic updates (uncomment to enable)
log "Installing cron job..."
"$SCRIPTS_DIR/install_cron.sh" || warn "Cron job installation failed"
```

Or run the script manually:

```bash
./scripts/install_cron.sh
```

## Omarchy-Specific Notes

After installing Omarchy:
1. Setup WiFi
2. Update system
3. Create snapshot: `sudo snapper -c root create --description "Fresh install, updated"`
4. Clone janstrap and run `./install_all.sh`
