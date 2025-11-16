#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/sddm.sh"
echo "[config_sddm] using $TARGET"
if [[ -f "$TARGET" ]]; then
  if [[ $EUID -ne 0 ]]; then
    echo "[config_sddm] escalating to root for system config"
    if command -v sudo >/dev/null 2>&1; then
      # Try non-interactive first, then interactive
      if sudo -n true 2>/dev/null; then
        exec sudo bash "$TARGET"
      else
        exec sudo bash "$TARGET"
      fi
    elif command -v doas >/dev/null 2>&1; then
      exec doas bash "$TARGET"
    elif command -v pkexec >/dev/null 2>&1; then
      exec pkexec bash "$TARGET"
    else
      echo "[config_sddm] No sudo/doas/pkexec available. Run this as root: bash $TARGET"; exit 1
    fi
  else
    exec bash "$TARGET"
  fi
else
  echo "[config_sddm] missing: $TARGET"; exit 0
fi