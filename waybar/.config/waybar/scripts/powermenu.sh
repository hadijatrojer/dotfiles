#!/bin/bash

chosen=$(echo -e "  Lock\n  Reboot\n󰗼  Logout\n  Shutdown\n⏾  Suspend" | fuzzel --dmenu --prompt "Power Menu " --lines 5 --width 20)

case "$chosen" in
"  Lock")
  hyprlock
  ;;
"  Reboot")
  systemctl reboot
  ;;
"󰗼  Logout")
  hyprctl dispatch exit
  ;;
"  Shutdown")
  systemctl poweroff
  ;;
"⏾  Suspend")
  systemctl suspend
  ;;
*) ;;
esac
