#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/rofi.sh"
echo "[config_rofi] using $TARGET"
if [[ -f "$TARGET" ]]; then
  sudo bash "$TARGET"
else
  echo "[config_rofi] missing: $TARGET"; exit 0
fi