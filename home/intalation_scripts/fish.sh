#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de Fish desde home/fish

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[fish] deploying to $CONFIG_DIR/fish"
mkdir -p "$CONFIG_DIR/fish"
cp -f "$ROOT_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish"
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/fish" 2>/dev/null || true
echo "[fish] done"