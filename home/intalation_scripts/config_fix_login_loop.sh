#!/bin/bash
set -euo pipefail

USER_NAME=${SUDO_USER:-$USER}
HOME_DIR="/home/$USER_NAME"

echo "[config_fix_login_loop] checking Xauthority ownership"
if [[ -f "$HOME_DIR/.Xauthority" ]]; then
  chown "$USER_NAME:$USER_NAME" "$HOME_DIR/.Xauthority" || true
fi
echo "[config_fix_login_loop] done"