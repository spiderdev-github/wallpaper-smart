#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------
# Config
# -----------------------------
CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/wallpaper-smart/config.json}"

# Fallbacks (si pas de config)
WALLDIR_DEFAULT="$HOME/Images/wallpaper"
LAT_FALLBACK="48.5839"   # Strasbourg
LON_FALLBACK="7.7455"

log() { echo "[$(date '+%F %T')] $*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "ERREUR: commande manquante: $1"
    exit 1
  }
}

need_cmd curl
need_cmd jq

# -----------------------------
# Desktop detection
# -----------------------------
DESKTOP="${XDG_CURRENT_DESKTOP:-}"
DESKTOP="${DESKTOP,,}"  # lowercase

# -----------------------------
# KDE wallpaper setter
# -----------------------------
set_wallpaper_kde() {
  local file="$1"

  command -v qdbus >/dev/null 2>&1 || {
    log "ERREUR: qdbus manquant (installe: sudo apt install qdbus-qt5)"
    return 1
  }

  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var allDesktops = desktops();
for (i=0; i<allDesktops.length; i++) {
  d = allDesktops[i];
  d.wallpaperPlugin = 'org.kde.image';
  d.currentConfigGroup = Array('Wallpaper','org.kde.image','General');
  d.writeConfig('Image', 'file://$file');
}
"
}

# -----------------------------
# Lire config (safe)
# -----------------------------
WALLDIR="$WALLDIR_DEFAULT"
if [[ -f "$CONFIG_FILE" ]]; then
  WALLDIR="$(jq -r '.wallpaper_dir // empty' "$CONFIG_FILE" 2>/dev/null || true)"
  [[ -z "$WALLDIR" || "$WALLDIR" == "null" ]] && WALLDIR="$WALLDIR_DEFAULT"
fi

WALL_THEME="default"
if [[ -f "$CONFIG_FILE" ]]; then
  WALL_THEME="$(jq -r '.wallpaper_theme // "default"' "$CONFIG_FILE" 2>/dev/null || echo "default")"
fi
[[ -z "$WALL_THEME" || "$WALL_THEME" == "null" ]] && WALL_THEME="default"

TEMPLATEDIR="$WALLDIR/templates/$WALL_THEME"

BASEDIR="$TEMPLATEDIR/base"
METEODIR="$TEMPLATEDIR/meteo"
TARGET="$WALLDIR/current.png"

mkdir -p "$BASEDIR" "$METEODIR"

# Schedule defaults
NUIT_START=19
AUBE_START=5
MIDI_START=11
COUCHER_START=17

if [[ -f "$CONFIG_FILE" ]]; then
  NUIT_START="$(jq -r '.schedule.nuit_start // 19' "$CONFIG_FILE" 2>/dev/null || echo 19)"
  AUBE_START="$(jq -r '.schedule.aube_start // 5' "$CONFIG_FILE" 2>/dev/null || echo 5)"
  MIDI_START="$(jq -r '.schedule.midi_start // 11' "$CONFIG_FILE" 2>/dev/null || echo 11)"
  COUCHER_START="$(jq -r '.schedule.coucher_start // 17' "$CONFIG_FILE" 2>/dev/null || echo 17)"
fi

# -----------------------------
# enabled_images : true par défaut
# -----------------------------
is_enabled_image() {
  local rel="$1"  # ex: templates/default/meteo/pluie_aube.png
  [[ -f "$CONFIG_FILE" ]] || return 0

  local v
  v="$(jq -r --arg rel "$rel" '
      if (.enabled_images | type == "object") and (.enabled_images | has($rel)) then
        .enabled_images[$rel]
      else
        true
      end
    ' "$CONFIG_FILE" 2>/dev/null || echo "true")"
  [[ "$v" == "true" ]]
}

# -----------------------------
# Géoloc
# -----------------------------
GEO_MODE="auto_ip"
FIXED_LAT="$LAT_FALLBACK"
FIXED_LON="$LON_FALLBACK"
CITY_NAME="Strasbourg"

if [[ -f "$CONFIG_FILE" ]]; then
  GEO_MODE="$(jq -r '.geolocation.mode // "auto_ip"' "$CONFIG_FILE" 2>/dev/null || echo "auto_ip")"
  FIXED_LAT="$(jq -r '.geolocation.fixed.lat // 48.5839' "$CONFIG_FILE" 2>/dev/null || echo "$LAT_FALLBACK")"
  FIXED_LON="$(jq -r '.geolocation.fixed.lon // 7.7455' "$CONFIG_FILE" 2>/dev/null || echo "$LON_FALLBACK")"
  CITY_NAME="$(jq -r '.geolocation.city_name // "Strasbourg"' "$CONFIG_FILE" 2>/dev/null || echo "Strasbourg")"
fi

LAT="$LAT_FALLBACK"
LON="$LON_FALLBACK"

geoloc_auto_ip() {
  local geo
  geo="$(curl -fsSL "https://ipapi.co/json/" 2>/dev/null || true)"
  LAT="$(echo "$geo" | jq -r '.latitude // empty' 2>/dev/null || true)"
  LON="$(echo "$geo" | jq -r '.longitude // empty' 2>/dev/null || true)"

  if [[ -z "$LAT" || "$LAT" == "null" || -z "$LON" || "$LON" == "null" ]]; then
    LAT="$LAT_FALLBACK"
    LON="$LON_FALLBACK"
  fi
}

geoloc_fixed() {
  LAT="$FIXED_LAT"
  LON="$FIXED_LON"
  if [[ -z "$LAT" || "$LAT" == "null" || -z "$LON" || "$LON" == "null" ]]; then
    LAT="$LAT_FALLBACK"
    LON="$LON_FALLBACK"
  fi
}

geoloc_city() {
  local q url res
  q="$(printf '%s' "$CITY_NAME" | jq -sRr @uri)"
  url="https://nominatim.openstreetmap.org/search?q=${q}&format=json&limit=1"
  res="$(curl -fsSL -A "wallpaper-smart/1.0" "$url" 2>/dev/null || true)"

  LAT="$(echo "$res" | jq -r '.[0].lat // empty' 2>/dev/null || true)"
  LON="$(echo "$res" | jq -r '.[0].lon // empty' 2>/dev/null || true)"

  if [[ -z "$LAT" || "$LAT" == "null" || -z "$LON" || "$LON" == "null" ]]; then
    LAT="$LAT_FALLBACK"
    LON="$LON_FALLBACK"
  fi
}

case "$GEO_MODE" in
  auto_ip) geoloc_auto_ip ;;
  fixed)   geoloc_fixed ;;
  city)    geoloc_city ;;
  *)       geoloc_auto_ip ;;
esac

# -----------------------------
# Météo Open-Meteo
# -----------------------------
CODE="0"
METEO_RAW="$(curl -fsSL "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=weather_code" 2>/dev/null || true)"
CODE="$(echo "$METEO_RAW" | jq -r '.current.weather_code // 0' 2>/dev/null || echo 0)"

WEATHER_BUCKET="clear"
case "$CODE" in
  0) WEATHER_BUCKET="clear" ;;
  1|2|3) WEATHER_BUCKET="cloudy" ;;
  45|48) WEATHER_BUCKET="fog" ;;
  51|53|55|56|57|61|63|65|66|67|80|81|82) WEATHER_BUCKET="rain" ;;
  71|73|75|77|85|86) WEATHER_BUCKET="snow" ;;
  95|96|99) WEATHER_BUCKET="thunder" ;;
  *) WEATHER_BUCKET="clear" ;;
esac

PREFIX="clair"
if [[ -f "$CONFIG_FILE" ]]; then
  PREFIX="$(jq -r --arg k "$WEATHER_BUCKET" '.weather_mapping[$k] // "clair"' "$CONFIG_FILE" 2>/dev/null || echo "clair")"
fi
[[ -z "$PREFIX" || "$PREFIX" == "null" ]] && PREFIX="clair"

# -----------------------------
# Moment du jour (horaires configurables)
# -----------------------------
HOUR="$(date +%H)"
HOUR=$((10#$HOUR))

MOMENT="nuit"
if (( HOUR >= AUBE_START && HOUR < MIDI_START )); then
  MOMENT="aube"
elif (( HOUR >= MIDI_START && HOUR < COUCHER_START )); then
  MOMENT="midi"
else
  if (( COUCHER_START < NUIT_START )); then
    if (( HOUR >= COUCHER_START && HOUR < NUIT_START )); then
      MOMENT="coucher"
    else
      MOMENT="nuit"
    fi
  else
    if (( HOUR >= COUCHER_START || HOUR < NUIT_START )); then
      MOMENT="coucher"
    else
      MOMENT="nuit"
    fi
  fi
fi

# -----------------------------
# Choix image finale
# -----------------------------
REL_METEO="templates/${WALL_THEME}/meteo/${PREFIX}_${MOMENT}.png"
CANDIDATE="$WALLDIR/$REL_METEO"
BASE="$BASEDIR/${MOMENT}.png"

CHOSEN="$BASE"
if [[ -f "$CANDIDATE" ]] && is_enabled_image "$REL_METEO"; then
  CHOSEN="$CANDIDATE"
fi

if [[ ! -f "$CHOSEN" ]]; then
  if [[ -f "$BASEDIR/nuit.png" ]]; then
    CHOSEN="$BASEDIR/nuit.png"
  else
    log "ERREUR: aucune image trouvée. Attendu: $BASE (et/ou $CANDIDATE)"
    exit 1
  fi
fi

# -----------------------------
# Skip if same as current (state json)
# -----------------------------
STATE_JSON="$WALLDIR/current.json"


# Rel path of the chosen wallpaper (relative to WALLDIR)
REL_CHOSEN="${CHOSEN#"$WALLDIR/"}"

# Read previous rel if exists
PREV_REL=""
if [[ -f "$STATE_JSON" ]]; then
  PREV_REL="$(jq -r '.rel // ""' "$STATE_JSON" 2>/dev/null || true)"
fi

# If same rel and target already exists, do nothing
if [[ -n "$PREV_REL" && "$PREV_REL" == "$REL_CHOSEN" && -f "$TARGET" ]]; then
  log "✅ Wallpaper: $CHOSEN (moment=$MOMENT | bucket=$WEATHER_BUCKET | prefix=$PREFIX | code=$CODE | LAT=$LAT LON=$LON)"
  log "==> Wallpaper unchanged, skip apply (rel=$REL_CHOSEN)"
  exit 0
fi

# Write new state (even if apply may fail later, this avoids loops)
jq -n \
  --arg rel "$REL_CHOSEN" \
  --arg abs "$CHOSEN" \
  --arg moment "$MOMENT" \
  --arg bucket "$WEATHER_BUCKET" \
  --arg prefix "$PREFIX" \
  --arg code "$CODE" \
  --arg lat "$LAT" \
  --arg lon "$LON" \
  --arg ts "$(date -Is)" \
  '{rel:$rel, abs:$abs, moment:$moment, bucket:$bucket, prefix:$prefix, code:$code, lat:$lat, lon:$lon, ts:$ts}' \
  > "$STATE_JSON"



cp -f "$CHOSEN" "$TARGET"

# -----------------------------
# Apply wallpaper GNOME / KDE
# -----------------------------
if [[ "$DESKTOP" == *"gnome"* ]]; then
  if gsettings set org.gnome.desktop.background picture-uri "file://$TARGET" 2>/dev/null; then
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$TARGET" 2>/dev/null || true
    log "✅ Wallpaper: $CHOSEN (moment=$MOMENT | bucket=$WEATHER_BUCKET | prefix=$PREFIX | code=$CODE | LAT=$LAT LON=$LON)"
  else
    warn "gsettings a échoué (session GNOME pas prête). Fichier prêt: $TARGET"
  fi

elif [[ "$DESKTOP" == *"kde"* || "$DESKTOP" == *"plasma"* ]]; then
  if set_wallpaper_kde "$TARGET"; then
    log "✅ Wallpaper: $CHOSEN (KDE | moment=$MOMENT | bucket=$WEATHER_BUCKET | prefix=$PREFIX | code=$CODE | LAT=$LAT LON=$LON)"
  else
    log "WARN: echec KDE. Fichier pret: $TARGET"
  fi

else
  log "WARN: Desktop non supporte ($XDG_CURRENT_DESKTOP). Fichier pret: $TARGET"
fi
