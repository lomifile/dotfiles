#!/usr/bin/env bash

set -uo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
	exit 1
fi

bluetoothctl power on >/dev/null 2>&1 || true

paired_raw=$(bluetoothctl devices Paired 2>/dev/null || true)

menu="__SCAN__: Scan for new device…"$'\n'

if [ -n "$paired_raw" ]; then
	while IFS= read -r line; do
		tag=$(echo "$line" | awk '{print $1}')
		mac=$(echo "$line" | awk '{print $2}')
		base_name=$(echo "$line" | cut -d' ' -f3-)

		if [ "$tag" != "Device" ]; then
			continue
		fi

		if ! [[ "$mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
			continue
		fi

		info=$(bluetoothctl info "$mac" 2>/dev/null || true)

		alias=$(echo "$info" | awk -F': ' '/^\s*Alias:/ {print $2; exit}')
		name_field=$(echo "$info" | awk -F': ' '/^\s*Name:/ {print $2; exit}')

		if [ -n "${alias:-}" ]; then
			display_name="$alias"
		elif [ -n "${name_field:-}" ]; then
			display_name="$name_field"
		else
			display_name="$base_name"
		fi

		icon_field=$(echo "$info" | awk -F': ' '/^\s*Icon:/ {print $2; exit}')
		case "$icon_field" in
		audio-headset | audio-headphones | audio-card)
			type_icon="  "
			;;
		phone | audio-phone)
			type_icon="  "
			;;
		input-mouse)
			type_icon="  "
			;;
		input-keyboard)
			type_icon="  "
			;;
		input-gaming)
			type_icon="  "
			;;
		*)
			type_icon="  "
			;;
		esac

		if echo "$info" | grep -q "Connected: yes"; then
			state_icon=" "
			state_text="connected"
		else
			state_icon=" "
			state_text="offline"
		fi

		label="$state_icon $type_icon $display_name [$state_text]"
		menu+="$label"$'\n'
	done <<<"$paired_raw"
fi

choice=$(printf '%s\n' "$menu" | cut -d: -f2- | wofi --dmenu --prompt "Bluetooth")
[ -z "$choice" ] && exit 0

selected_key=$(printf '%s\n' "$menu" | grep -F "$choice" | head -n1 | cut -d: -f1)

if [ "$selected_key" = "__SCAN__" ]; then
	scan_output=$(timeout 15 bluetoothctl scan on 2>/dev/null || true)
	bluetoothctl scan off >/dev/null 2>&1 || true

	scan_menu=""
	while IFS= read -r line; do
		tag=$(echo "$line" | awk '{print $1}')
		mac=$(echo "$line" | awk '{print $2}')
		name=$(echo "$line" | cut -d' ' -f3-)

		if [ "$tag" != "Device" ]; then
			continue
		fi
		if ! [[ "$mac" =~ ^([0-9A-F]{2}:){5}[0-9A-F]{2}$ ]]; then
			continue
		fi
		if [ -z "$name" ]; then
			continue
		fi

		label=" $name"
		scan_menu+="$mac::$label"$'\n'
	done <<<"$(printf '%s\n' "$scan_output" | awk '/^Device /')"

	if [ -z "$scan_menu" ]; then
		notify-send "Bluetooth" "No new devices found"
		exit 0
	fi

	scan_choice=$(printf '%s\n' "$scan_menu" | cut -d: -f2- | wofi --dmenu --prompt "Pair device")
	[ -z "$scan_choice" ] && exit 0

	scan_mac=$(printf '%s\n' "$scan_menu" | grep -F "$scan_choice" | head -n1 | cut -d: -f1)

	if bluetoothctl pair "$scan_mac" >/dev/null 2>&1 &&
		bluetoothctl trust "$scan_mac" >/dev/null 2>&1 &&
		bluetoothctl connect "$scan_mac" >/dev/null 2>&1; then
		notify-send "Bluetooth" "Paired and connected $scan_choice"
	else
		notify-send "Bluetooth" "Failed to pair $scan_choice"
	fi

	exit 0
fi

mac="$selected_key"

info=$(bluetoothctl info "$mac" 2>/dev/null || true)
if echo "$info" | grep -q "Connected: yes"; then
	bluetoothctl disconnect "$mac" >/dev/null 2>&1
	notify-send "Bluetooth" "Disconnected $choice"
else
	if bluetoothctl connect "$mac" >/dev/null 2>&1; then
		notify-send "Bluetooth" "Connected $choice"
	else
		notify-send "Bluetooth" "Failed to connect $choice"
	fi
fi
