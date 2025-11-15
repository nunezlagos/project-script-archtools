#!/usr/bin/env bash
set -euo pipefail

# Launch Kitty as a floating window on current desktop
bspc rule -a kittyfloat state=floating center=true
kitty --class kittyfloat &