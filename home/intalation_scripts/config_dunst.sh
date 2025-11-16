#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/dunst.sh"
echo "[config_dunst] using $TARGET"
if [[ -f "$TARGET" ]]; then
  bash "$TARGET"
else
  echo "[config_dunst] missing: $TARGET"; exit 0
fi