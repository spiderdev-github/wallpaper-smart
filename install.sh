#!/usr/bin/env bash
set -Eeuo pipefail

# wallpaper-smart - portable installer
# - Works on most Linux distros (best-effort dependency install)
# - Supports systemd user timers when available, otherwise installs scripts + desktop launcher only

DEBUG=0
WALLDIR_DEFAULT="$HOME/.config/wallpaper-smart/wallpaper"
CFG_DIR="$HOME/.config/wallpaper-smart"
CFG_FILE="$CFG_DIR/config.json"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/src"
TEMPLATES_SRC="$SCRIPT_DIR/wallpaper/templates"
LANG_SRC="$SCRIPT_DIR/lang"

usage() {
  cat <<EOF
Usage: $0 [--no-geo] [--debug] [--walldir <path>] [--minutes <n>] [--no-deps] [--force-templates]

Options:
  --walldir <path>        Wallpaper root directory (default: $WALLDIR_DEFAULT)
                          New layout uses: <walldir>/templates/<theme>/{base,meteo}
  --minutes <n>           Timer frequency (systemd only) (default: 10)
  --no-deps               Do not attempt to install dependencies (only checks + hints)
  --force-templates        Overwrite existing templates files (default: copy missing only)
  --debug                 Verbose mode
  --no-geo                Do not attempt to detect geolocation during install
EOF
}


LAT_DEFAULT="48.8566"
LON_DEFAULT="2.3522"
CITY_DEFAULT="Paris"
NO_GEO=0

WALLDIR="$WALLDIR_DEFAULT"
MINUTES="10"
NO_DEPS=0
FORCE_TEMPLATES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) DEBUG=1; shift ;;
    --walldir) WALLDIR="${2:-}"; shift 2 ;;
    --minutes) MINUTES="${2:-}"; shift 2 ;;
    --no-deps) NO_DEPS=1; shift ;;
    --force-templates) FORCE_TEMPLATES=1; shift ;;
    --no-geo) NO_GEO=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Argument inconnu: $1"; usage; exit 2 ;;
  esac
done

if [[ "$DEBUG" == "1" ]]; then
  set -x
fi

log()  { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }
trap 'err "Erreur ligne $LINENO: $BASH_COMMAND"' ERR

# Expand ~
WALLDIR="${WALLDIR/#\~/$HOME}"

# -----------------------------
# Pre-checks (repo layout)
# -----------------------------
req_file() { [[ -f "$1" ]] || { err "Manquant: $1"; exit 1; }; }

req_file "$SRC/wallpaper-smart.sh"
req_file "$SRC/wallpaper-smart-ui"
req_file "$SRC/wallpaper-smart-on-style-change.sh"
req_file "$SRC/wallpaper-smart-mkplaceholders.sh"

req_file "$SRC/wallpaper-smart.service"
req_file "$SRC/wallpaper-smart.timer"

req_file "$SRC/wallpaper-smart-style-hook.service"
req_file "$SRC/wallpaper-smart-style-hook.path"

log "WALLDIR:  $WALLDIR"
log "Minutes:  $MINUTES"
log "SRC:      $SRC"

# -----------------------------
# Dependency installation (best-effort)
# -----------------------------
has() { command -v "$1" >/dev/null 2>&1; }

detect_pm() {
  if has apt-get; then echo "apt"; return; fi
  if has dnf; then echo "dnf"; return; fi
  if has yum; then echo "yum"; return; fi
  if has pacman; then echo "pacman"; return; fi
  if has zypper; then echo "zypper"; return; fi
  if has apk; then echo "apk"; return; fi
  echo "unknown"
}

install_deps() {
  local pm="$1"
  local sudo_cmd=""
  if [[ "$(id -u)" -ne 0 ]]; then
    if has sudo; then sudo_cmd="sudo"; else sudo_cmd=""; fi
  fi

  case "$pm" in
    apt)
      $sudo_cmd apt-get update
      $sudo_cmd apt-get install -y \
        curl jq \
        python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
        gir1.2-appindicator3-0.1 \
        xdg-utils || true
      ;;
    dnf)
      $sudo_cmd dnf install -y \
        curl jq \
        python3 python3-gobject gtk3 python3-cairo \
        libappindicator-gtk3 \
        xdg-utils || true
      ;;
    yum)
      $sudo_cmd yum install -y \
        curl jq \
        python3 python3-gobject gtk3 python3-cairo \
        xdg-utils || true
      ;;
    pacman)
      $sudo_cmd pacman -Sy --noconfirm \
        curl jq \
        python python-gobject gtk3 python-cairo \
        libappindicator-gtk3 \
        xdg-utils || true
      ;;
    zypper)
      $sudo_cmd zypper --non-interactive install \
        curl jq \
        python3 python3-gobject-Gdk gtk3 python3-cairo \
        xdg-utils || true
      ;;
    apk)
      $sudo_cmd apk add --no-cache \
        curl jq \
        python3 py3-gobject3 gtk+3.0 py3-cairo \
        xdg-utils || true
      ;;
    *)
      return 1
      ;;
  esac

  return 0
}

deps_hint() {
  cat <<'EOF'
Dépendances requises (noms variables selon distro) :
  - bash, curl, jq
  - python3
  - GTK3 + PyGObject (gi) + Cairo bindings
  - AppIndicator3 (pour l'icône système)

Exemples :
  Debian/Ubuntu:
    sudo apt install curl jq python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 gir1.2-appindicator3-0.1
  Fedora:
    sudo dnf install curl jq python3 python3-gobject gtk3 python3-cairo libappindicator-gtk3
  Arch:
    sudo pacman -S curl jq python python-gobject gtk3 python-cairo libappindicator-gtk3
  openSUSE:
    sudo zypper install curl jq python3 python3-gobject-Gdk gtk3 python3-cairo libappindicator3
EOF
}

check_python_gi() {
  python3 - <<'PY' >/dev/null 2>&1 || return 1
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gio, GLib
PY
}


get_geo_defaults() {
  # Best effort IP geolocation (one-shot). Falls back to defaults.
  local geo_json out

  GEO_LAT="$LAT_DEFAULT"
  GEO_LON="$LON_DEFAULT"
  GEO_CITY="$CITY_DEFAULT"

  command -v curl >/dev/null 2>&1 || return 0
  command -v python3 >/dev/null 2>&1 || return 0

  geo_json="$(curl -fsSL --max-time 4 "https://ipapi.co/json/" 2>/dev/null || true)"
  [[ -z "$geo_json" ]] && return 0

out="$(printf '%s' "$geo_json" | python3 -c '
import json, sys
try:
    d = json.loads(sys.stdin.read())
    lat = d.get("latitude")
    lon = d.get("longitude")
    city = (d.get("city") or "").strip()
    region = (d.get("region") or "").strip()
    country = (d.get("country_name") or d.get("country") or "").strip()

    parts = [p for p in (city, region, country) if p]
    city_label = ", ".join(parts) if parts else ""

    if lat is None or lon is None:
        print("||")
    else:
        print(f"{float(lat)}|{float(lon)}|{city_label}")
except Exception:
    print("||")
' 2>/dev/null || true)"
  # Parse "lat|lon|city"
  local lat lon city
  lat="${out%%|*}"
  out="${out#*|}"
  lon="${out%%|*}"
  city="${out#*|}"


  if [[ -n "$lat" && -n "$lon" ]]; then
    GEO_LAT="$lat"
    GEO_LON="$lon"
  fi
  if [[ -n "$city" ]]; then
    GEO_CITY="$city"
  fi
}


log "Vérification dépendances..."
NEED_INSTALL=0
for c in curl jq python3; do
  if ! has "$c"; then NEED_INSTALL=1; fi
done

if ! check_python_gi; then NEED_INSTALL=1; fi

if [[ "$NEED_INSTALL" == "1" ]]; then
  if [[ "$NO_DEPS" == "1" ]]; then
    warn "Dépendances manquantes et --no-deps activé."
    deps_hint
  else
    pm="$(detect_pm)"
    if [[ "$pm" == "unknown" ]]; then
      warn "Gestionnaire de paquets non détecté. Installation auto impossible."
      deps_hint
    else
      log "Installation dépendances via: $pm (best-effort)"
      if ! install_deps "$pm"; then
        warn "Installation auto impossible sur ce système."
        deps_hint
      fi
    fi
  fi
fi

# Re-check critical bits
if ! has curl || ! has python3; then
  err "curl et/ou python3 manquants - impossible de continuer."
  exit 1
fi
if ! check_python_gi; then
  err "PyGObject/GTK3 manquant (import gi / Gtk / GLib échoue)."
  deps_hint
  exit 1
fi

# -----------------------------
# Install files
# -----------------------------
log "Création dossiers utilisateur..."
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/systemd/user"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$CFG_DIR"
mkdir -p "$WALLDIR"

log "Installation scripts dans ~/.local/bin/ (écrasement si existant)..."
install -m 755 "$SRC/wallpaper-smart.sh" "$HOME/.local/bin/wallpaper-smart.sh"
install -m 755 "$SRC/wallpaper-smart-ui" "$HOME/.local/bin/wallpaper-smart-ui"
install -m 755 "$SRC/wallpaper-smart-mkplaceholders.sh" "$HOME/.local/bin/wallpaper-smart-mkplaceholders.sh"


install -m 755 "$SRC/wallpaper-smart-on-style-change.sh" "$HOME/.local/bin/wallpaper-smart-on-style-change.sh"
install -m 644 "$SRC/wallpaper-smart-style-hook.service" "$HOME/.config/systemd/user/wallpaper-smart-style-hook.service"
install -m 644 "$SRC/wallpaper-smart-style-hook.path" "$HOME/.config/systemd/user/wallpaper-smart-style-hook.path"

log "Installation de l'icône système..."
ICON_DIR="$HOME/.local/share/icons"
mkdir -p "$ICON_DIR"
if [[ -f "$SRC/wallpaper-smart-tray-icon.svg" ]]; then
    install -m 644 "$SRC/wallpaper-smart-tray-icon.svg" "$ICON_DIR/wallpaper-smart-tray.svg"
    log "✅ Icône système installée"
    if has gtk-update-icon-cache; then
        gtk-update-icon-cache -f -t "$ICON_DIR" 2>/dev/null || true
    fi
else
    warn "Icône système non trouvée: $SRC/wallpaper-smart-tray-icon.svg (l'app fonctionnera sans icône personnalisée)"
fi

log "Installation des langs dans ~/.config/wallpaper-smart (écrasement si existant)..."

# Templates (optional)
copy_templates() {
  [[ -d "$TEMPLATES_SRC" ]] || { warn "Templates absents: $TEMPLATES_SRC"; return 0; }
  mkdir -p "$WALLDIR/templates"

  if has rsync; then
    if [[ "$FORCE_TEMPLATES" == "1" ]]; then
      log "Copie templates (rsync overwrite)..."
      rsync -a --delete "$TEMPLATES_SRC"/ "$WALLDIR/templates"/
    else
      log "Copie templates (rsync, sans écraser les fichiers existants)..."
      rsync -a --ignore-existing "$TEMPLATES_SRC"/ "$WALLDIR/templates"/
    fi
    log "Copie des langues (rsync, sans écraser les fichiers existants)..."
    rsync -a --delete "$LANG_SRC"/ "$CFG_DIR/lang"/

  else
    log "rsync non présent -> copie simple (cp)."
    if [[ "$FORCE_TEMPLATES" == "1" ]]; then
      cp -a "$TEMPLATES_SRC"/. "$WALLDIR/templates"/
    else
      # copy missing only
      (cd "$TEMPLATES_SRC" && find . -type d -print0) | while IFS= read -r -d '' d; do
        mkdir -p "$WALLDIR/templates/$d"
      done
      (cd "$TEMPLATES_SRC" && find . -type f -print0) | while IFS= read -r -d '' f; do
        if [[ ! -f "$WALLDIR/templates/$f" ]]; then
          cp -a "$TEMPLATES_SRC/$f" "$WALLDIR/templates/$f"
        fi
      done
    fi
    cp -a "$LANG_SRC"/. "$CFG_DIR/lang"/
  fi
}
copy_templates

# -----------------------------
# Config JSON (create or upgrade) - using python (portable)
# -----------------------------
if [[ "$NO_GEO" != "1" ]]; then
  get_geo_defaults
  log "Geo defaults: lat=$GEO_LAT lon=$GEO_LON city=$GEO_CITY"
  GEO_MODE="auto_ip"
else
  log "No geoloc on install"
  GEO_LAT="$LAT_DEFAULT"
  GEO_LON="$LON_DEFAULT"
  GEO_CITY="$CITY_DEFAULT"
  GEO_MODE="fixed"
fi


log "Création/upgrade config: $CFG_FILE"
python3 - <<PY
import json, os
from pathlib import Path

cfg_dir = Path(os.path.expanduser("${CFG_DIR}"))
cfg_file = Path(os.path.expanduser("${CFG_FILE}"))
walldir = os.path.expanduser("${WALLDIR}")
minutes = int("${MINUTES}")

default = {
  "wallpaper_dir": walldir,
  "wallpaper_theme": "default",
  "schedule": {
    "aube_start": "05:00",
    "midi_start": "11:00",
    "coucher_start": "16:00",
    "nuit_start": "19:00"
  },
  "geolocation": {
    "mode": "${GEO_MODE}",
    "fixed": {"lat": ${GEO_LAT}, "lon": ${GEO_LON}},
    "city_name": "${GEO_CITY}",
    "preset": "none",
  },
  "weather_mapping": {
    "clear": "clair",
    "cloudy": "nuageux",
    "fog": "brouillard",
    "rain": "pluie",
    "snow": "neige",
    "thunder": "orage"
  },
  "timer_minutes": minutes,
  "enabled_images": {},
  "ui": {
    "language": "system"
  }
}



def deep_merge(a, b):
  # returns merged dict: a as defaults, b overrides; merges nested dicts
  out = dict(a)
  for k, v in (b or {}).items():
    if isinstance(v, dict) and isinstance(out.get(k), dict):
      out[k] = deep_merge(out[k], v)
    else:
      out[k] = v
  return out

cfg_dir.mkdir(parents=True, exist_ok=True)
if cfg_file.exists():
  try:
    user = json.loads(cfg_file.read_text(encoding="utf-8"))
    if not isinstance(user, dict):
      user = {}
  except Exception:
    user = {}
  merged = deep_merge(default, user)
else:
  merged = default

# If user provided --minutes, we always sync timer_minutes
merged["timer_minutes"] = minutes

cfg_file.write_text(json.dumps(merged, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

# -----------------------------
# systemd user timer (if available)
# -----------------------------
HAS_SYSTEMD=0
if has systemctl && [[ -d "$HOME/.config/systemd/user" || -d "/usr/lib/systemd/user" || -d "/lib/systemd/user" ]]; then
  HAS_SYSTEMD=1
fi

if [[ "$HAS_SYSTEMD" == "1" ]]; then
  log "Installation systemd units (user)..."
  mkdir -p "$HOME/.config/systemd/user"
  install -m 644 "$SRC/wallpaper-smart.service" "$HOME/.config/systemd/user/wallpaper-smart.service"
  install -m 644 "$SRC/wallpaper-smart.timer" "$HOME/.config/systemd/user/wallpaper-smart.timer"
  install -m 644 "$SRC/wallpaper-smart-style-hook.path" "$HOME/.config/systemd/user/wallpaper-smart-style-hook.path"
  
  log "Creation overrides systemd (CONFIG_FILE + frequence)..."
  mkdir -p "$HOME/.config/systemd/user/wallpaper-smart.service.d"
  cat > "$HOME/.config/systemd/user/wallpaper-smart.service.d/override.conf" <<EOF
[Service]
Environment=CONFIG_FILE=$CFG_FILE
ExecStartPre=/bin/sleep 5
EOF

  mkdir -p "$HOME/.config/systemd/user/wallpaper-smart.timer.d"
  cat > "$HOME/.config/systemd/user/wallpaper-smart.timer.d/override.conf" <<EOF
[Timer]
OnStartupSec=1s
OnUnitActiveSec=${MINUTES}min
Persistent=true
EOF

  log "Activation service & timer systemd..."
  systemctl --user daemon-reload || true
  
  systemctl --user enable --now wallpaper-smart.service || true
  systemctl --user start --now wallpaper-smart.service || true

  systemctl --user enable --now wallpaper-smart.timer || true
  systemctl --user start --now wallpaper-smart.timer || true

  log "Activation hook changement de style (systemd path)..."
  systemctl --user enable  --now wallpaper-smart-style-hook.path || true
else
  warn "systemd user non detecte -> timer non installe."
  warn "Tu peux lancer le script manuellement, ou le planifier via cron/anacron."
fi

# -----------------------------
# Desktop entry
# -----------------------------
log "Creation .desktop..."
DESKTOP="$HOME/.local/share/applications/wallpaper-smart.desktop"
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=Wallpaper Smart
Comment=Configurer le fond d'ecran dynamique (heure + meteo)
Keywords=wallpaper;fond;meteo;
Exec=$HOME/.local/bin/wallpaper-smart-ui
Icon=wallpaper-smart-tray
Terminal=false
Categories=Settings;Utility;
StartupNotify=true
EOF

# Refresh desktop db if available
if has update-desktop-database; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

log "✅ Installation terminee."
echo ""
echo "📁 Arborescence wallpapers :"
echo "  $WALLDIR/"
echo "    templates/<theme>/base/   -> aube.png, midi.png, coucher.png, nuit.png (OBLIGATOIRE)"
echo "    templates/<theme>/meteo/  -> <prefix>_<moment>.png (OPTIONNEL)"
echo ""
echo "▶ Test manuel :"
echo "  CONFIG_FILE=\"$CFG_FILE\" ~/.local/bin/wallpaper-smart.sh"
echo ""
echo "🖥️ Lancer l'app :"
echo "  ~/.local/bin/wallpaper-smart-ui"
if [[ "$HAS_SYSTEMD" != "1" ]]; then
  echo ""
  echo "⏱️ Sans systemd, exemple cron (toutes les ${MINUTES} min) :"
  echo "  crontab -e"
  echo "  */${MINUTES} * * * * CONFIG_FILE=\"$CFG_FILE\" $HOME/.local/bin/wallpaper-smart.sh >/dev/null 2>&1"
fi
