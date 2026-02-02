#!/usr/bin/env bash
set -Eeuo pipefail

DEBUG=0
WALLDIR_DEFAULT="$HOME/Images/wallpaper"
CFG_DIR="$HOME/.config/wallpaper-smart"
CFG_FILE="$CFG_DIR/config.json"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/src"
ASSETS_WALLPAPER_DIR="$SCRIPT_DIR/wallpaper"

usage() {
  echo "Usage: $0 [--debug] [--walldir <path>] [--minutes <n>]"
}

WALLDIR="$WALLDIR_DEFAULT"
MINUTES="10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) DEBUG=1; shift ;;
    --walldir) WALLDIR="${2:-}"; shift 2 ;;
    --minutes) MINUTES="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 2 ;;
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
WALLDIR="${WALLDIR/#\~/$HOME}"

# Checks
[[ -d "$SRC" ]] || { err "Missing dir: $SRC"; exit 1; }
[[ -f "$SRC/wallpaper-smart.sh" ]] || { err "Missing: $SRC/wallpaper-smart.sh"; exit 1; }
[[ -f "$SRC/wallpaper-smart-ui" ]] || { err "Missing: $SRC/wallpaper-smart-ui"; exit 1; }
[[ -f "$SRC/wallpaper-smart.service" ]] || { err "Missing: $SRC/wallpaper-smart.service"; exit 1; }
[[ -f "$SRC/wallpaper-smart.timer" ]] || { err "Missing: $SRC/wallpaper-smart.timer"; exit 1; }
[[ -f "$SRC/wallpaper-smart-mkplaceholders.sh" ]] || { err "Missing: $SRC/wallpaper-smart-mkplaceholders.sh"; exit 1; }

log "WALLDIR:  $WALLDIR"
log "Minutes:  $MINUTES"
log "SRC:      $SRC"

# 1) Dirs
log "Creating dirs..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$CFG_DIR"

# 2) Deps
log "Installing deps..."
sudo apt update
sudo apt install -y \
  curl jq \
  python3-gi python3-gi-cairo gir1.2-gtk-3.0

# 3) Install scripts (overwrite)
log "Installing scripts into ~/.local/bin/ ..."
install -m 755 "$SRC/wallpaper-smart.sh" "$HOME/.local/bin/wallpaper-smart.sh"
install -m 755 "$SRC/wallpaper-smart-ui" "$HOME/.local/bin/wallpaper-smart-ui"
install -m 755 "$SRC/wallpaper-smart-mkplaceholders.sh" "$HOME/.local/bin/wallpaper-smart-mkplaceholders.sh"

# 4) Install systemd units (overwrite)
log "Installing systemd units..."
install -m 644 "$SRC/wallpaper-smart.service" "$HOME/.config/systemd/user/wallpaper-smart.service"
install -m 644 "$SRC/wallpaper-smart.timer"   "$HOME/.config/systemd/user/wallpaper-smart.timer"

# 5) Wallpaper templates (copy)
# Expected tree:
#   $WALLDIR/templates/<theme>/{base,meteo}/...
if [[ -d "$ASSETS_WALLPAPER_DIR/templates" ]]; then
  log "Copying wallpaper templates to $WALLDIR/templates/ ..."
  mkdir -p "$WALLDIR/templates"
  # rsync preferred, fallback to cp
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$ASSETS_WALLPAPER_DIR/templates/" "$WALLDIR/templates/"
  else
    rm -rf "$WALLDIR/templates"
    mkdir -p "$WALLDIR/templates"
    cp -a "$ASSETS_WALLPAPER_DIR/templates/." "$WALLDIR/templates/"
  fi
else
  warn "No wallpaper/templates dir found next to installer, skipping templates copy."
fi

# 6) Config JSON (create or upgrade)
DEFAULT_JSON="$(cat <<EOF
{
  "wallpaper_dir": "$WALLDIR",
  "wallpaper_theme": "default",
  "schedule": {
    "nuit_start": 19,
    "aube_start": 5,
    "midi_start": 11,
    "coucher_start": 17
  },
  "geolocation": {
    "mode": "auto_ip",
    "fixed": { "lat": 48.5839, "lon": 7.7455 },
    "city_name": "Strasbourg",
    "preset": "none"
  },
  "weather_mapping": {
    "clear": "clair",
    "cloudy": "nuageux",
    "fog": "brouillard",
    "rain": "pluie",
    "snow": "neige",
    "thunder": "orage"
  },
  "timer_minutes": $MINUTES,
  "enabled_images": {}
}
EOF
)"

if [[ ! -f "$CFG_FILE" ]]; then
  log "Creating default config: $CFG_FILE"
  printf "%s\n" "$DEFAULT_JSON" > "$CFG_FILE"
else
  log "Existing config detected -> soft upgrade (add missing keys only)"
  TMP="$(mktemp)"
  echo "$DEFAULT_JSON" > "$TMP.default"
  cp "$CFG_FILE" "$TMP.user"
  jq -s '.[0] * .[1]' "$TMP.default" "$TMP.user" > "$TMP"
  mv "$TMP" "$CFG_FILE"
  rm -f "$TMP.default" "$TMP.user" || true

  if [[ -n "${MINUTES:-}" ]]; then
    jq ".timer_minutes = $MINUTES" "$CFG_FILE" > "$CFG_FILE.tmp" && mv "$CFG_FILE.tmp" "$CFG_FILE"
  fi
fi

# 7) Overrides systemd : CONFIG_FILE + timer freq
log "Creating systemd overrides..."
mkdir -p "$HOME/.config/systemd/user/wallpaper-smart.service.d"
cat > "$HOME/.config/systemd/user/wallpaper-smart.service.d/override.conf" <<EOF
[Service]
Environment=CONFIG_FILE=$CFG_FILE
EOF

mkdir -p "$HOME/.config/systemd/user/wallpaper-smart.timer.d"
cat > "$HOME/.config/systemd/user/wallpaper-smart.timer.d/override.conf" <<EOF
[Timer]
OnUnitActiveSec=${MINUTES}min
EOF

# 8) App icon (always install a local icon so GNOME never shows a blank tile)
log "Installing app icon..."
ICON_NAME="wallpaper-smart"

# Prefer a repo-provided icon if present
ICON_SRC=""
for cand in \
  "$SCRIPT_DIR/icon/wallpaper-smart.svg" \
  "$SCRIPT_DIR/icon/wallpaper-smart.png" \
  "$SCRIPT_DIR/assets/wallpaper-smart.svg" \
  "$SCRIPT_DIR/assets/wallpaper-smart.png"
do
  if [[ -f "$cand" ]]; then
    ICON_SRC="$cand"
    break
  fi
done

if [[ -n "$ICON_SRC" ]]; then
  if [[ "$ICON_SRC" == *.svg ]]; then
    install -m 644 "$ICON_SRC" "$HOME/.local/share/icons/hicolor/scalable/apps/${ICON_NAME}.svg"
  else
    install -m 644 "$ICON_SRC" "$HOME/.local/share/icons/hicolor/256x256/apps/${ICON_NAME}.png"
  fi
else
  # Fallback SVG (simple wallpaper icon)
  cat > "$HOME/.local/share/icons/hicolor/scalable/apps/${ICON_NAME}.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect x="24" y="40" width="208" height="176" rx="20" fill="#2B2B2B"/>
  <rect x="36" y="52" width="184" height="152" rx="14" fill="#E95420"/>
  <circle cx="84" cy="92" r="16" fill="#FFFFFF" opacity="0.95"/>
  <path d="M48 188l54-54 30 30 28-28 48 52H48z" fill="#FFFFFF" opacity="0.90"/>
</svg>
EOF
fi

# Update icon cache (best effort)
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

# 9) Desktop entry
log "Creating .desktop entry..."
DESKTOP="$HOME/.local/share/applications/wallpaper-smart.desktop"
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=Wallpaper Smart
Comment=Configurer le fond d’écran dynamique (heure + météo)
Exec=$HOME/.local/bin/wallpaper-smart-ui
Icon=wallpaper-smart
Terminal=false
Categories=Settings;Utility;
StartupNotify=true
EOF

update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true


# 10) Enable timer
log "Enabling timer..."
systemctl --user daemon-reload
systemctl --user enable --now wallpaper-smart.timer

log "Done."
echo ""
echo "Wallpaper dir:"
echo "  $WALLDIR/"
echo "    templates/<theme>/base/   -> aube.png midi.png coucher.png nuit.png (required)"
echo "    templates/<theme>/meteo/  -> <prefix>_<moment>.png (optional)"
echo ""
echo "Manual test:"
echo "  CONFIG_FILE=\"$CFG_FILE\" ~/.local/bin/wallpaper-smart.sh"
echo ""
echo "Launch UI:"
echo "  ~/.local/bin/wallpaper-smart-ui"
