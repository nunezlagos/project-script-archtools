#!/usr/bin/env bash
set -euo pipefail

# Wallpapers con miniaturas, previsualización y confirmación
# Este script funciona como modo script de Rofi y también puede lanzarse directo.

WALL_DIR="${WALL_DIR:-$HOME/.config/wallpaper}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper_preview"
STATE_SEL="$CACHE_DIR/selected.txt"
STATE_PID="$CACHE_DIR/preview.pid"
mkdir -p "$CACHE_DIR"

list_images(){
  find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    -printf '%p\n' | sort
}

apply_wallpaper(){
  local img="$1"
  if [ -z "$img" ]; then return 0; fi
  # Solo X11: overlay de transición suave y aplicación con feh
  if command -v mpv >/dev/null 2>&1; then
    # Primero detenemos preview (si existe) para evitar solapamiento
    stop_preview || true
    # Imagen nítida con fade-in para dar sensación de "aclara desde el centro"
    mpv "$img" --fs --no-border --ontop --really-quiet \
        --image-display-duration=1.0 --keep-open=no --no-input-default-bindings \
        --vf=lavfi=[fade=in:0:60] >/dev/null 2>&1 &
    echo $! > "$STATE_PID"
    sleep 0.50
  fi
  feh --bg-fill "$img"
  # Apaga overlay para simular transición de salida con picom
  if [ -f "$STATE_PID" ]; then
    kill "$(cat "$STATE_PID")" >/dev/null 2>&1 || true
    rm -f "$STATE_PID"
  fi
}

start_preview(){
  local img="$1"
  if [ -z "$img" ]; then return 0; fi
  # Vista previa en pantalla (encima), que se desvanece con picom
  if command -v mpv >/dev/null 2>&1; then
    # Preview con blur y ligera viñeta para simular "todo en blur" desde el centro
    mpv "$img" --fs --no-border --ontop --really-quiet --image-display-duration=inf \
        --keep-open=yes --no-input-default-bindings \
        --vf=lavfi=[gblur=sigma=16:steps=2, vignette=0.25:0.45, fade=in:0:45] >/dev/null 2>&1 &
    echo $! > "$STATE_PID"
    sleep 0.25
  elif command -v feh >/dev/null 2>&1; then
    feh -F -Z --no-fehbg --class WallpaperPreview --title "Preview" "$img" >/dev/null 2>&1 &
    echo $! > "$STATE_PID"
    sleep 0.25
  fi
}

stop_preview(){
  if [ -f "$STATE_PID" ]; then
    kill "$(cat "$STATE_PID")" >/dev/null 2>&1 || true
    rm -f "$STATE_PID"
  fi
}

print_list(){
  local imgs
  mapfile -t imgs < <(list_images)
  if [ ${#imgs[@]} -eq 0 ]; then
    echo "No se encontraron imágenes en $WALL_DIR"
    return 0
  fi
  for img in "${imgs[@]}"; do
    bn="${img##*/}"
    printf "%s\0icon\x1f%s\n" "$bn" "$img"
  done
}

case "${ROFI_RETV:-0}" in
  0)
    # Primera invocación: lista con miniaturas
    print_list
    ;;
  1)
    sel="$(cat)"
    if [ "$sel" = "Confirmar" ]; then
      if [ -f "$STATE_SEL" ]; then
        img="$(cat "$STATE_SEL")"
        apply_wallpaper "$img"
        stop_preview
        rm -f "$STATE_SEL" || true
      fi
      exit 0
    elif [ "$sel" = "Cancelar" ]; then
      stop_preview
      rm -f "$STATE_SEL" || true
      print_list
    else
      img="$WALL_DIR/$sel"
      if [ -f "$img" ]; then
        printf "%s" "$img" > "$STATE_SEL"
        start_preview "$img"
        printf "Confirmar\nCancelar\n"
      else
        match="$(list_images | grep -F "/$sel" | head -n1 || true)"
        if [ -n "$match" ]; then
          printf "%s" "$match" > "$STATE_SEL"
          start_preview "$match"
          printf "Confirmar\nCancelar\n"
        else
          print_list
        fi
      fi
    fi
    ;;
  *)
    print_list
    ;;
esac

if [ -z "${ROFI_RETV:-}" ]; then
  bspc rule -a Rofi -o state=floating center=true
  rofi -show wallpapers -modi "wallpapers:$0" -show-icons \
       -theme ~/.config/rofi/config.rasi \
       -theme-str 'element-icon { size: 80; } listview { lines: 10; }'
  bspc rule -r Rofi || true
fi