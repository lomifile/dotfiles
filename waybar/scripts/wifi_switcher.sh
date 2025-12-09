#!/usr/bin/env bash
set -euo pipefail

wifi_iface=$(nmcli device status | awk '$2=="wifi" && $3!="unavailable" {print $1; exit}')
[ -z "$wifi_iface" ] && exit 0

choice=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list ifname "$wifi_iface" | awk -F: '
{
  active=$1; ssid=$2; signal=$3;
  if (ssid == "") next;
  icon="󰤟";
  if (signal >= 80) icon="󰤨";
  else if (signal >= 60) icon="󰤥";
  else if (signal >= 40) icon="󰤢";
  else if (signal >= 20) icon="󰤟";
  prefix = (active=="yes") ? " " : "   ";
  printf "%s%s  (%s%%)\n", prefix, ssid, signal;
}' | wofi --dmenu --prompt "Wi-Fi" --allow-markup=false)

[ -z "$choice" ] && exit 0

ssid=$(echo "$choice" | sed -E 's/^ *//; s/ *\([0-9]+%\)//')

nmcli dev wifi connect "$ssid" ifname "$wifi_iface" || exit 1
