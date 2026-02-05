#!/usr/bin/env bash
set -Eeuo pipefail

# Wallpaper Smart - Uninstaller (portable)
# Works with:
# - systemd user (service/timer) if present
# - cron fallback (if installed)

REMOVE_CONFIG=0
REMOVE_WALLPAPERS=0
WALLPAPERS_DIR=""

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --remove-config          Remove config directory (~/.config/wallpaper-smart)
  --remove-wallpapers      Remove wallpapers templates directory (templates/...) inside --wallpapers-dir
  --wallpapers-dir DIR     Wallpapers root directory (same as wallpaper_dir in config.json)
  -h, --help               Show help

Examples:
  $0
  $0 --remove-config
  $0 --remove-wallpapers --wallpapers-dir "$HOME/Images/wallpaper"
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-config) REMOVE_CONFIG=1; shift ;;
    --remove-wallpapers) REMOVE_WALLPAPERS=1; shift ;;
    --wallpapers-dir) WALLPAPERS_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

log()  { printf "[1;32m[INFO][0m %s
" "$*"; }
warn() { printf "[1;33m[WARN][0m %s
" "$*"; }
err()  { printf "[1;31m[ERR ][0m %s
" "$*"; }
trap 'err "Error line $LINENO: $BASH_COMMAND"' ERR

CONFIG_DIR="$HOME/.config/wallpaper-smart"
CONFIG_FILE="$CONFIG_DIR/config.json"

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
CRON_MARKER_FILE="$CONFIG_DIR/.cron-installed"

SERVICE="wallpaper-smart.service"
TIMER="wallpaper-smart.timer"
STYLE_HOOK="wallpaper-smart-style-hook.service"
STYLE_HOOK_PATH="wallpaper-smart-style-hook.path"
DESKTOP_FILE="$APP_DIR/wallpaper-smart.desktop"
APP_ICON="$APP_DIR/wallpaper-smart.png"

# Expand ~ if needed
WALLPAPERS_DIR="${WALLPAPERS_DIR/#\~/$HOME}"

log "Stopping services (best effort)..."

# systemd user (if available)
if command -v systemctl >/dev/null 2>&1; then
  if systemctl --user list-unit-files 2>/dev/null | grep -q "^${TIMER}"; then
    systemctl --user disable --now "$TIMER" >/dev/null 2>&1 || true
  fi
  if systemctl --user list-unit-files 2>/dev/null | grep -q "^${SERVICE}"; then
    systemctl --user disable --now "$SERVICE" >/dev/null 2>&1 || true
  fi
  if systemctl --user list-unit-files 2>/dev/null | grep -q "^${STYLE_HOOK}"; then
    systemctl --user disable --now "$STYLE_HOOK" >/dev/null 2>&1 || true
  fi
  if systemctl --user list-unit-files 2>/dev/null | grep -q "^${STYLE_HOOK_PATH}"; then
    systemctl --user disable --now "$STYLE_HOOK_PATH" >/dev/null 2>&1 || true
  fi
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

# cron fallback removal (installed by portable installer)
if command -v crontab >/dev/null 2>&1; then
  # Remove any lines containing wallpaper-smart.sh (safe)
  (crontab -l 2>/dev/null | grep -v "wallpaper-smart.sh" || true) | crontab - 2>/dev/null || true
fi

log "Removing installed files..."

# scripts
rm -f "$BIN_DIR/wallpaper-smart.sh" || true
rm -f "$BIN_DIR/wallpaper-smart-ui" || true
rm -f "$BIN_DIR/wallpaper-smart-mkplaceholders.sh" || true
rm -f "$BIN_DIR/wallpaper-smart-on-style-change.sh" || true

# systemd units
rm -f "$SYSTEMD_USER_DIR/$SERVICE" || true
rm -f "$SYSTEMD_USER_DIR/$TIMER" || true
rm -f "$SYSTEMD_USER_DIR/$STYLE_HOOK" || true
rm -f "$SYSTEMD_USER_DIR/$STYLE_HOOK_PATH" || true
rm -rf "$SYSTEMD_USER_DIR/${SERVICE}.d" || true
rm -rf "$SYSTEMD_USER_DIR/${TIMER}.d" || true
rm -rf "$SYSTEMD_USER_DIR/${STYLE_HOOK}.d" || true
# desktop entry + icon
rm -f "$DESKTOP_FILE" || true
rm -f "$APP_ICON" || true

# hicolor icon (if installer placed it)
rm -f "$ICON_DIR/256x256/apps/wallpaper-smart.png" || true
rm -f "$ICON_DIR/128x128/apps/wallpaper-smart.png" || true
rm -f "$ICON_DIR/64x64/apps/wallpaper-smart.png" || true
rm -f "$ICON_DIR/48x48/apps/wallpaper-smart.png" || true

# refresh desktop db (best effort)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache "$HOME/.local/share/icons" >/dev/null 2>&1 || true
fi

# Optional: remove wallpapers templates
if [[ "$REMOVE_WALLPAPERS" == "1" ]]; then
  if [[ -z "$WALLPAPERS_DIR" ]]; then
    warn "--remove-wallpapers used but --wallpapers-dir is missing. Skipping."
  else
    TEMPLATES_DIR="$WALLPAPERS_DIR/templates"
    if [[ -d "$TEMPLATES_DIR" ]]; then
      log "Removing templates dir: $TEMPLATES_DIR"
      rm -rf "$TEMPLATES_DIR" || true
    else
      warn "Templates dir not found: $TEMPLATES_DIR"
    fi
  fi
fi

# Optional: remove config
if [[ "$REMOVE_CONFIG" == "1" ]]; then
  if [[ -d "$CONFIG_DIR" ]]; then
    log "Removing config dir: $CONFIG_DIR"
    rm -rf "$CONFIG_DIR" || true
  fi
fi

log "Done. Wallpaper Smart uninstalled."
