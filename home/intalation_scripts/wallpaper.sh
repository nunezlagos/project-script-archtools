#!/bin/bash
set -euo pipefail

# Copia wallpapers desde home/wallpaper a ~/.config/wallpaper

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"       # .../home
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"   # proyecto raíz
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[wallpaper] deploying to $CONFIG_DIR/wallpaper"
mkdir -p "$CONFIG_DIR/wallpaper"
# Preferir carpeta 'wallpaper' en raíz del proyecto; si no existe, usar 'home/wallpaper'
if [[ -d "$REPO_ROOT/wallpaper" ]]; then
  cp -rf "$REPO_ROOT/wallpaper/"* "$CONFIG_DIR/wallpaper/" 2>/dev/null || true
elif [[ -d "$ROOT_DIR/wallpaper" ]]; then
  cp -rf "$ROOT_DIR/wallpaper/"* "$CONFIG_DIR/wallpaper/" 2>/dev/null || true
else
  echo "[wallpaper] source not found in repo root or home/ (skipping)"
fi
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/wallpaper" 2>/dev/null || true
echo "[wallpaper] done"