#!/usr/bin/env bash

options="Lock\nLogout\nReboot\nShutdown\nSuspend"

selected=$(echo -e "$options" | wofi --dmenu --prompt "Session")

case $selected in
Lock)
	hyprctl dispatch exec "gtklock"
	;;
Logout)
	hyprctl dispatch exit
	;;
Reboot)
	systemctl reboot
	;;
Shutdown)
	systemctl poweroff
	;;
Suspend)
	systemctl suspend
	;;
esac
