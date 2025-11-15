#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de Kitty desde home/kitty

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[kitty] deploying to $CONFIG_DIR/kitty"
mkdir -p "$CONFIG_DIR/kitty"
cp -rf "$ROOT_DIR/kitty/"* "$CONFIG_DIR/kitty/" 2>/dev/null || true
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/kitty" 2>/dev/null || true
echo "[kitty] done"