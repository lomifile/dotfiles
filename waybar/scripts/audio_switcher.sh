#!/usr/bin/env bash
set -euo pipefail

default_sink=$(pactl info | awk -F': ' '/Default Sink/ {print $2}')

choice=$(pactl list short sinks | awk -v def="$default_sink" '
{
  name=$2
  label=$2
  if (name == def) label = " " name
  print label
}' | wofi --dmenu --prompt "Audio output" --allow-markup=false)

[ -z "$choice" ] && exit 0

sink_name=$(echo "$choice" | sed 's/^ //')

pactl set-default-sink "$sink_name"

pactl list short sink-inputs | awk '{print $1}' | while read -r input; do
	pactl move-sink-input "$input" "$sink_name"
done
