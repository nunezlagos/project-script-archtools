#!/usr/bin/env bash
set -euo pipefail

# TUI de wallpapers en terminal (Kitty) con preview y confirmación.
# Este script se puede ejecutar directamente; sin argumentos abre Kitty flotante/centrada.

WALL_DIR="${WALL_DIR:-$HOME/.config/wallpaper}"

list_images(){
  find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    -printf '%f\n' | sort
}

preview_cmd(){
  local path="$WALL_DIR/{}"
  if command -v chafa >/dev/null 2>&1; then
    echo "chafa --symbols block --fill solid --size 80x40 '$path'"
  elif command -v img2txt >/dev/null 2>&1; then
    echo "img2txt --width=80 '$path'"
  elif command -v viu >/dev/null 2>&1; then
    echo "viu -w 80 -h 40 '$path'"
  else
    echo "identify -verbose '$path' | head -n 20"
  fi
}

apply_wallpaper(){
  local img="$1"
  [ -z "$img" ] && return 0
  if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v swww >/dev/null 2>&1; then
    swww init 2>/dev/null || true
    swww img "$img" \
      --transition-type grow \
      --transition-pos 50%,50% \
      --transition-bezier 0.19,1,0.22,1 \
      --transition-duration 1.1 \
      --transition-fps 60
  else
    # X11: blur breve y luego overlay nítido con fade-in; después aplica con feh
    if command -v mpv >/dev/null 2>&1; then
      # Fase 1: overlay con blur corto
      mpv "$img" --fs --no-border --ontop --really-quiet \
        --image-display-duration=0.60 --keep-open=no --no-input-default-bindings \
        --vf=lavfi=[gblur=sigma=16:steps=2, vignette=0.25:0.45] >/dev/null 2>&1 &
      sleep 0.65
      # Fase 2: overlay nítido con fade-in
      mpv "$img" --fs --no-border --ontop --really-quiet \
        --image-display-duration=1.0 --keep-open=no --no-input-default-bindings \
        --vf=lavfi=[fade=in:0:60] >/dev/null 2>&1 &
      sleep 0.50
    fi
    feh --bg-fill "$img"
  fi
  notify-send "Wallpaper aplicado" "$(basename "$img")" || true
}

tui(){
  # Encabezado estilo "bar" simple
  echo "====================== Wallpapers ======================"
  echo "Directorio: $WALL_DIR"
  echo "Selecciona con ↑↓ y Enter. Previsualiza a la derecha."
  echo "========================================================"

  mapfile -t imgs < <(list_images)
  if [ ${#imgs[@]} -eq 0 ]; then
    echo "No se encontraron imágenes en $WALL_DIR"
    read -r -p "Presiona Enter para salir..." _
    exit 0
  fi

  local preview
  preview=$(preview_cmd)

  if command -v fzf >/dev/null 2>&1; then
    local pick
    pick=$(printf "%s\n" "${imgs[@]}" | fzf --preview "$preview" \
      --preview-window=right,60%,border-rounded \
      --height=85% --layout=reverse --prompt="Wallpaper > ") || true
    if [ -z "${pick:-}" ]; then
      echo "Cancelado."
      exit 0
    fi

    # Confirmación ligera simulando "bar"
    clear
    echo "====================== Confirmación ====================="
    echo "Seleccionado: $pick"
    echo "Directorio: $WALL_DIR"
    echo "[c] Confirmar    [x] Cancelar"
    echo "========================================================="
    read -r -n1 -p "Acción (c/x): " ans; echo ""
    if [[ "${ans:-}" =~ ^[cC]$ ]]; then
      apply_wallpaper "$WALL_DIR/$pick"
    else
      echo "Cancelado."
    fi
  else
    # Fallback sin fzf: selector simple
    local i=1
    for bn in "${imgs[@]}"; do
      printf "%2d) %s\n" "$i" "$bn"; i=$((i+1))
    done
    read -r -p "Número: " num
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#imgs[@]} ]; then
      echo "Selección inválida"; exit 1
    fi
    local pick="${imgs[$((num-1))]}"
    echo "Seleccionado: $pick"
    read -r -p "Confirmar? (y/N): " yn
    if [[ "${yn:-}" =~ ^[yY]$ ]]; then
      apply_wallpaper "$WALL_DIR/$pick"
    else
      echo "Cancelado."
    fi
  fi
}

launch_term(){
  # Usa wrapper genérico para abrir Kitty flotante y centrada
  ~/.config/polybar/scripts/open_float.sh WallpaperTUI \
    "kitty --class WallpaperTUI -T 'Wallpapers' \
      -o remember_window_size=no \
      -o initial_window_width=980 \
      -o initial_window_height=640 \
      -e bash -lc '~/.config/polybar/scripts/wallpaper_tui.sh tui'"
}

case "${1:-}" in
  tui) tui ;;
  *) launch_term ;;
esac