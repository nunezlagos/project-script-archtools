#!/bin/bash
set -euo pipefail

USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

SRC_FILE="$ROOT_DIR/command-list"

echo "[config_command_list] copying command-list to / and home"
if [[ -f "$SRC_FILE" ]]; then
  install -m 0644 "$SRC_FILE" "/command-list" || true
  install -m 0644 "$SRC_FILE" "$HOME_DIR/command-list" || true
  chown "$USER_NAME:$USER_NAME" "$HOME_DIR/command-list" 2>/dev/null || true
else
  echo "[config_command_list] source file not found: $SRC_FILE"
fi
echo "[config_command_list] done"