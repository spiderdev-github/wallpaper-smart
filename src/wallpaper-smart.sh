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
need_cmd gsettings

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
# -----------------------------
# enabled_images : true par défaut
# -----------------------------
is_enabled_image() {
  local rel="$1"  # ex: meteo/pluie_aube.png
  [[ -f "$CONFIG_FILE" ]] || return 0

  # IMPORTANT:
  # jq 'a // b' retourne b si a est null *ou false*.
  # Or ici, false signifie "désactivé" → on doit le respecter.
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
  # Nominatim: usage modéré (config, pas polling)
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

# Classifier Open-Meteo -> bucket
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

# Mapping bucket -> prefix dossier/fichier
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

# Assumptions:
# - Les "start" indiquent à partir de quelle heure commence le segment.
# - Le segment "nuit" est celui qui est avant aube_start.
# - Ordre attendu: nuit_start > coucher_start ou inverse selon tes choix => on calcule via plages simples.
#
# On va faire simple et robuste:
# - aube:   [aube_start, midi_start)
# - midi:   [midi_start, coucher_start)
# - coucher:[coucher_start, nuit_start) si coucher_start < nuit_start
# - nuit:   le reste
MOMENT="nuit"

if (( HOUR >= AUBE_START && HOUR < MIDI_START )); then
  MOMENT="aube"
elif (( HOUR >= MIDI_START && HOUR < COUCHER_START )); then
  MOMENT="midi"
else
  # coucher dépend de la position de nuit_start
  if (( COUCHER_START < NUIT_START )); then
    if (( HOUR >= COUCHER_START && HOUR < NUIT_START )); then
      MOMENT="coucher"
    else
      MOMENT="nuit"
    fi
  else
    # cas où nuit_start est plus petit (ex nuit à 0/1/2h)
    # coucher: [coucher_start, 24) U [0, nuit_start)
    if (( HOUR >= COUCHER_START || HOUR < NUIT_START )); then
      MOMENT="coucher"
    else
      MOMENT="nuit"
    fi
  fi
fi

# -----------------------------
# Choix image finale
# priorité: meteo si fichier existe ET activé, sinon base
# -----------------------------
REL_METEO="templates/${WALL_THEME}/meteo/${PREFIX}_${MOMENT}.png"
CANDIDATE="$WALLDIR/$REL_METEO"
BASE="$BASEDIR/${MOMENT}.png"


CHOSEN="$BASE"
if [[ -f "$CANDIDATE" ]] && is_enabled_image "$REL_METEO"; then
  CHOSEN="$CANDIDATE"
fi

# Fallback si base absente
if [[ ! -f "$CHOSEN" ]]; then
  # si candidate absent/désactivé + base manquante, tente base nuit
  if [[ -f "$BASEDIR/nuit.png" ]]; then
    CHOSEN="$BASEDIR/nuit.png"
  else
    log "ERREUR: aucune image trouvée. Attendu: $BASE (et/ou $CANDIDATE)"
    exit 1
  fi
fi

# Copie dans un fichier stable
cp -f "$CHOSEN" "$TARGET"

# Appliquer sur GNOME (light + dark)
if gsettings set org.gnome.desktop.background picture-uri "file://$TARGET" 2>/dev/null; then
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$TARGET" 2>/dev/null || true
  log "✅ Wallpaper: $CHOSEN (moment=$MOMENT | bucket=$WEATHER_BUCKET | prefix=$PREFIX | code=$CODE | LAT=$LAT LON=$LON)"
else
  warn "gsettings a échoué (session GNOME pas prête). Fichier prêt: $TARGET"
fi
