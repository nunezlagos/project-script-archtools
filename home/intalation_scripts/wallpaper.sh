#!/bin/bash
set -euo pipefail

# Copia wallpapers desde home/wallpaper a ~/.config/wallpaper

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[wallpaper] deploying to $CONFIG_DIR/wallpaper"
mkdir -p "$CONFIG_DIR/wallpaper"
cp -rf "$ROOT_DIR/wallpaper/"* "$CONFIG_DIR/wallpaper/" 2>/dev/null || true
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/wallpaper" 2>/dev/null || true
echo "[wallpaper] done"