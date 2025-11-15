#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de SXHKD desde home/sxhkd

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[sxhkd] deploying to $CONFIG_DIR/sxhkd"
mkdir -p "$CONFIG_DIR/sxhkd"
cp -f "$ROOT_DIR/sxhkd/sxhkdrc" "$CONFIG_DIR/sxhkd/sxhkdrc"
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/sxhkd" 2>/dev/null || true
echo "[sxhkd] done"