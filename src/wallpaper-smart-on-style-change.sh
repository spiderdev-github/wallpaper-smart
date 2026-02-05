#!/usr/bin/env bash
set -euo pipefail

# Read GNOME color scheme (works on GNOME 42+)
scheme="$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")"

# Normalize
case "$scheme" in
  prefer-dark) mode="dark" ;;
  prefer-light|default|*) mode="light" ;;
esac

# Optional: export to service via systemd env (if you want)
# systemctl --user set-environment DESKTOP_STYLE="$mode"

# Restart (or start) your wallpaper service so it re-applies
systemctl --user restart wallpaper-smart.service
