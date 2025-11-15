#!/bin/bash
set -euo pipefail

USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
CONFIG_DIR="$HOME_DIR/.config"

echo "[config_dirs] creating base directories in $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
for d in bspwm sxhkd polybar polybar/scripts picom dunst kitty fish wallpaper rofi; do
  mkdir -p "$CONFIG_DIR/$d"
done
chown -R "$USER_NAME:$USER_NAME" "$CONFIG_DIR" 2>/dev/null || true
echo "[config_dirs] done"