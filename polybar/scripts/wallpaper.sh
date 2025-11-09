#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/.config/wallpaper"
mapfile -t IMAGES < <(find "$WALL_DIR" -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' -o -name '*.webp' \) | sort)

if [ ${#IMAGES[@]} -eq 0 ]; then
  notify-send "Wallpapers" "No se encontraron imágenes en $WALL_DIR" || true
  exit 0
fi

apply_wallpaper(){
  local img="$1"
  # Wayland con swww (transición real)
  if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v swww >/dev/null 2>&1; then
    swww init 2>/dev/null || true
    swww img "$img" --transition-type wipe --transition-duration 0.7 --transition-fps 60 --transition-step 90
  else
    # X11: transición breve con overlay de mpv; luego aplica con feh
    if command -v mpv >/dev/null 2>&1; then
      mpv "$img" --fs --no-border --ontop --really-quiet \
          --image-display-duration=0.8 --keep-open=no --no-input-default-bindings \
          --vf=lavfi=[fade=in:0:45] >/dev/null 2>&1 &
      sleep 0.5
    fi
    feh --bg-fill "$img"
    pkill -f "mpv.* --fs.*$(printf %q "$img")" >/dev/null 2>&1 || true
  fi
}

## Flotar y centrar la ventana de Rofi temporalmente
bspc rule -a Rofi -o state=floating center=true

# Construye lista con glifos en lugar de icon markup
CHOICE=$(printf "%s\n" "${IMAGES[@]}" | while read -r img; do 
  bn="${img##*/}"; printf "  %s\n" "$bn"; 
done | rofi -dmenu -i -p "Wallpapers" -theme ~/.config/rofi/config.rasi)

bspc rule -r Rofi || true

if [ -n "${CHOICE:-}" ]; then
  # Elimina el prefijo del glifo "  " para obtener el nombre real
  bn="${CHOICE#  }"
  IMG="$WALL_DIR/$bn"
  apply_wallpaper "$IMG"
  notify-send "Wallpaper aplicado" "$bn" || true
fi