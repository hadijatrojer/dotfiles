#!/bin/bash

chosen=$(echo -e "  Lock\n  Reboot\n󰗼  Logout\n  Shutdown\n⏾  Suspend" | wofi --dmenu --i --width 260 --height 36 --prompt "Power Menu")

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
