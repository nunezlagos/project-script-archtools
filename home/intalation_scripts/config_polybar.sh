#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/polybar.sh"
echo "[config_polybar] using $TARGET"
if [[ -f "$TARGET" ]]; then
  sudo bash "$TARGET"
else
  echo "[config_polybar] missing: $TARGET"; exit 0
fi