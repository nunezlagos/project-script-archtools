#!/usr/bin/env bash
set -euo pipefail

dir=${1:-next}

# Get default source name
default_name=$(pactl info | awk -F': ' '/Default Source/ {print $2}')

# Build arrays of ids and names
mapfile -t sources < <(pactl list short sources)
ids=()
names=()
for line in "${sources[@]}"; do
  id=$(awk '{print $1}' <<<"$line")
  name=$(awk '{print $2}' <<<"$line")
  ids+=("$id")
  names+=("$name")
done

# Find current index
current_index=0
for i in "${!names[@]}"; do
  if [[ "${names[$i]}" == "$default_name" ]]; then
    current_index=$i
    break
  fi
done

if [[ "$dir" == "next" ]]; then
  next_index=$(( (current_index + 1) % ${#ids[@]} ))
else
  next_index=$(( (current_index - 1 + ${#ids[@]}) % ${#ids[@]} ))
fi

pactl set-default-source "${ids[$next_index]}"