#!/usr/bin/env bash
set -euo pipefail

# Launch Firefox as a floating window on current desktop
bspc rule -a FirefoxFloat state=floating center=true
firefox --class FirefoxFloat &

# Fallback: float and center focused window
sleep 0.3 || true
bspc node -t floating 2>/dev/null || true
bspc node -p center 2>/dev/null || true