#!/usr/bin/env bash
set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
	exit 1
fi

devices_raw=$(bluetoothctl devices Paired)

if [ -z "$devices_raw" ]; then
	notify-send "Bluetooth" "No paired devices"
	exit 0
fi

menu=""
while read -r line; do
	mac=$(echo "$line" | awk '{print $2}')
	name=$(echo "$line" | cut -d' ' -f3-)
	[ -z "$mac" ] && continue
	info=$(bluetoothctl info "$mac" || true)
	if echo "$info" | grep -q "Connected: yes"; then
		icon=""
		status="connected"
	else
		icon=""
		status="offline"
	fi
	menu+="$mac::$icon $name [$status]\n"
done <<<"$devices_raw"

choice=$(printf "%b" "$menu" | cut -d: -f2- | wofi --dmenu --prompt "Bluetooth" --allow-markup=false)
[ -z "$choice" ] && exit 0

selected_mac=$(printf "%b" "$menu" | grep "$choice" | head -n1 | cut -d: -f1)

if [ -z "$selected_mac" ]; then
	exit 0
fi

info=$(bluetoothctl info "$selected_mac" || true)
if echo "$info" | grep -q "Connected: yes"; then
	bluetoothctl disconnect "$selected_mac" >/dev/null 2>&1
	notify-send "Bluetooth" "Disconnected $choice"
else
	bluetoothctl connect "$selected_mac" >/dev/null 2>&1 && notify-send "Bluetooth" "Connected $choice"
fi
