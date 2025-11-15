#!/bin/bash
set -euo pipefail

# Instala/actualiza configuración de Dunst desde home/dunst

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[dunst] deploying to $CONFIG_DIR/dunst"
mkdir -p "$CONFIG_DIR/dunst"
cp -rf "$ROOT_DIR/dunst/"* "$CONFIG_DIR/dunst/" 2>/dev/null || true
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR/dunst" 2>/dev/null || true
echo "[dunst] done"