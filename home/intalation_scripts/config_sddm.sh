#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/sddm.sh"
echo "[config_sddm] using $TARGET"
if [[ -f "$TARGET" ]]; then
  if [[ $EUID -ne 0 ]]; then
    echo "[config_sddm] escalating to root for system config (sudo)"
    sudo bash "$TARGET"
  else
    bash "$TARGET"
  fi
else
  echo "[config_sddm] missing: $TARGET"; exit 0
fi