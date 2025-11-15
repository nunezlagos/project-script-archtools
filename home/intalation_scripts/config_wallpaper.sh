#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/wallpaper.sh"
echo "[config_wallpaper] using $TARGET"
if [[ -f "$TARGET" ]]; then
  sudo bash "$TARGET"
else
  echo "[config_wallpaper] missing: $TARGET"; exit 0
fi