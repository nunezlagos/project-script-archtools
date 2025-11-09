#!/usr/bin/env bash
set -euo pipefail

# Hacer flotante solo la nueva terminal (kitty)
# Regla temporal para clase única y eliminación posterior
bspc rule -a float-bash state=floating center=true
kitty --class float-bash &
sleep 1
bspc rule -r float-bash || true