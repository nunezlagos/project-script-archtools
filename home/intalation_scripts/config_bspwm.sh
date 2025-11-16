#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/bspwm.sh"
echo "[config_bspwm] using $TARGET"
if [[ -f "$TARGET" ]]; then
  bash "$TARGET"
else
  echo "[config_bspwm] missing: $TARGET"; exit 0
fi