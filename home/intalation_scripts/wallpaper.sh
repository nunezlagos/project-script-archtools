#!/bin/bash
set -euo pipefail

# Copia wallpapers desde el repositorio a ~/.config/wallpapers

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"       # .../home
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"   # proyecto raíz
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

DEST_DIR="$CONFIG_DIR/wallpapers"
LINK_COMPAT="$CONFIG_DIR/wallpaper"
echo "[wallpaper] deploying to $DEST_DIR"
mkdir -p "$DEST_DIR"
# Preferir carpeta 'wallpaper' en raíz del proyecto; si no existe, usar 'home/wallpaper'
if [[ -d "$REPO_ROOT/wallpaper" ]]; then
  cp -rf "$REPO_ROOT/wallpaper/"* "$DEST_DIR/" 2>/dev/null || true
elif [[ -d "$ROOT_DIR/wallpaper" ]]; then
  cp -rf "$ROOT_DIR/wallpaper/"* "$DEST_DIR/" 2>/dev/null || true
else
  echo "[wallpaper] source not found in repo root or home/ (skipping)"
fi
chown -R "$USER_NAME:$USER_NAME" "$DEST_DIR" 2>/dev/null || true
# Crear enlace de compatibilidad ~/.config/wallpaper -> ~/.config/wallpapers
if [[ ! -L "$LINK_COMPAT" ]]; then
  ln -sfn "wallpapers" "$LINK_COMPAT" 2>/dev/null || true
fi
echo "[wallpaper] done"