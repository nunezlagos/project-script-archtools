#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de Picom desde home/picom

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[picom] deploying to $CONFIG_DIR/picom"
mkdir -p "$CONFIG_DIR/picom"
cp -f "$ROOT_DIR/picom/picom.conf" "$CONFIG_DIR/picom/picom.conf"
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/picom" 2>/dev/null || true
echo "[picom] done"