#!/usr/bin/env bash
set -euo pipefail

mode=${1:-default}
time_str=$(date +'%H : %M')

if [[ "$mode" == "pulse" ]]; then
  # Resalta el reloj temporalmente usando color y subrayado
  echo "%{F#ffcc00}%{u#ffcc00}%{+u}${time_str}%{-u}%{F-}"
else
  echo "${time_str}"
fi