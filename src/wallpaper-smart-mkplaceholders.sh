#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/wallpaper-smart/config.json}"

command -v jq >/dev/null 2>&1 || { echo "[ERR] jq manquant (sudo apt install jq)"; exit 1; }

WALLDIR="$(jq -r '.wallpaper_dir' "$CONFIG_FILE")"
BASE="$WALLDIR/base"
METEO="$WALLDIR/meteo"

mkdir -p "$BASE" "$METEO"

MOMENTS=("aube" "midi" "coucher" "nuit")

# Mapping => prefixes
PREFIXES=()
for k in clear cloudy fog rain snow thunder; do
  p="$(jq -r --arg k "$k" '.weather_mapping[$k] // empty' "$CONFIG_FILE")"
  [[ -n "$p" ]] && PREFIXES+=("$p")
done

# Ensure ImageMagick
if ! command -v convert >/dev/null 2>&1; then
  echo "[INFO] Installation ImageMagick (convert)..."
  sudo apt update
  sudo apt install -y imagemagick
fi

mk_one() {
  local path="$1"
  local w="${2:-3840}"
  local h="${3:-2160}"

  # Ne jamais écraser
  [[ -f "$path" ]] && return 0

  mkdir -p "$(dirname "$path")"

  # Placeholder neutre, moderne, sans texte
  convert -size "${w}x${h}" xc:"#2B2B2B" \
    -fill "#343434" -draw "rectangle 80,80 $((w-80)),$((h-80))" \
    -fill "#404040" -draw "rectangle 120,120 $((w-120)),$((h-120))" \
    "$path"

  echo "[OK] placeholder créé: $path"
}

echo "[INFO] Génération placeholders (sans texte) dans: $WALLDIR"

# Base
for m in "${MOMENTS[@]}"; do
  mk_one "$BASE/${m}.png" 3840 2160
done

# Meteo (prefix × moments)
for p in "${PREFIXES[@]}"; do
  for m in "${MOMENTS[@]}"; do
    mk_one "$METEO/${p}_${m}.png" 3840 2160
  done
done

echo "[DONE] Placeholders créés (aucun fichier existant écrasé)."
