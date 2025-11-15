#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de Rofi desde home/rofi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[rofi] deploying to $CONFIG_DIR/rofi"
mkdir -p "$CONFIG_DIR/rofi"
cp -f "$ROOT_DIR/rofi/config.rasi" "$CONFIG_DIR/rofi/config.rasi"
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/rofi" 2>/dev/null || true
echo "[rofi] done"