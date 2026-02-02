#!/usr/bin/env bash
set -Eeuo pipefail

REMOVE_CONFIG=0
REMOVE_WALLPAPERS=0
REMOVE_IMAGES_DEFAULT="$HOME/Images/wallpaper"

usage() {
  cat <<EOF
Usage: $0 [--purge-config] [--purge-wallpapers] [--wallpapers-dir <path>] [--debug]

Options:
  --purge-config        Remove ~/.config/wallpaper-smart (config.json)
  --purge-wallpapers    Remove wallpapers dir (templates/...)
  --wallpapers-dir DIR  Wallpapers dir path (default: $REMOVE_IMAGES_DEFAULT)
  --debug               Debug mode (set -x)
EOF
}

DEBUG=0
WALLPAPERS_DIR="$REMOVE_IMAGES_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge-config) REMOVE_CONFIG=1; shift ;;
    --purge-wallpapers) REMOVE_WALLPAPERS=1; shift ;;
    --wallpapers-dir) WALLPAPERS_DIR="${2:-}"; shift 2 ;;
    --debug) DEBUG=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$DEBUG" == "1" ]]; then
  set -x
fi

log()  { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }
trap 'err "Error line $LINENO: $BASH_COMMAND"' ERR

# Expand ~
WALLPAPERS_DIR="${WALLPAPERS_DIR/#\~/$HOME}"

SERVICE="wallpaper-smart.service"
TIMER="wallpaper-smart.timer"
ICON_NAME="wallpaper-smart"

log "Stopping / disabling timer..."
systemctl --user disable --now "$TIMER" >/dev/null 2>&1 || true

log "Removing systemd user units..."
rm -f "$HOME/.config/systemd/user/$SERVICE" || true
rm -f "$HOME/.config/systemd/user/$TIMER" || true

log "Removing systemd overrides..."
rm -rf "$HOME/.config/systemd/user/${SERVICE}.d" || true
rm -rf "$HOME/.config/systemd/user/${TIMER}.d" || true

log "Reloading systemd user..."
systemctl --user daemon-reload >/dev/null 2>&1 || true

log "Removing scripts from ~/.local/bin/..."
rm -f "$HOME/.local/bin/wallpaper-smart.sh" || true
rm -f "$HOME/.local/bin/wallpaper-smart-ui" || true
rm -f "$HOME/.local/bin/wallpaper-smart-mkplaceholders.sh" || true

log "Removing .desktop..."
rm -f "$HOME/.local/share/applications/wallpaper-smart.desktop" || true
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

log "Removing app icon..."
rm -f "$HOME/.local/share/icons/hicolor/scalable/apps/${ICON_NAME}.svg" || true
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/${ICON_NAME}.png" || true
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

if [[ "$REMOVE_CONFIG" == "1" ]]; then
  log "Purging config: ~/.config/wallpaper-smart"
  rm -rf "$HOME/.config/wallpaper-smart" || true
else
  warn "Config kept (use --purge-config to remove)."
fi

if [[ "$REMOVE_WALLPAPERS" == "1" ]]; then
  if [[ -d "$WALLPAPERS_DIR" ]]; then
    log "Purging wallpapers: $WALLPAPERS_DIR"
    rm -rf "$WALLPAPERS_DIR"
  else
    warn "Wallpapers dir not found: $WALLPAPERS_DIR"
  fi
else
  warn "Wallpapers kept (use --purge-wallpapers to remove)."
fi

log "Uninstall finished."
echo ""
echo "Tip: check timers:"
echo "  systemctl --user list-timers | grep wallpaper-smart || true"
