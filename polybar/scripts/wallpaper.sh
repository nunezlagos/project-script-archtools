#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/.config/wallpaper"
mapfile -t IMAGES < <(find "$WALL_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \) | sort)

if [ ${#IMAGES[@]} -eq 0 ]; then
  notify-send "Wallpapers" "No se encontraron imágenes en $WALL_DIR" || true
  exit 0
fi

CHOICE=$(printf "%s\n" "${IMAGES[@]}" | sed "s|$WALL_DIR/||" | rofi -dmenu -i -p "Wallpaper" -theme ~/.config/rofi/config.rasi)

if [ -n "${CHOICE:-}" ]; then
  IMG="$WALL_DIR/$CHOICE"
  feh --bg-fill "$IMG"
  notify-send "Wallpaper aplicado" "$CHOICE" || true
fi