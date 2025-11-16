#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/eww.sh"
echo "[config_eww] using $TARGET"
if [[ -f "$TARGET" ]]; then
  bash "$TARGET"
else
  echo "[config_eww] missing: $TARGET"; exit 0
fi