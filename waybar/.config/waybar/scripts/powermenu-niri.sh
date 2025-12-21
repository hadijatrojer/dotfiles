#!/bin/bash

chosen=$(echo -e "  Lock\n  Reboot\n󰗼  Logout\n  Shutdown\n⏾  Suspend" | wofi --dmenu --i --width 260 --height 360 --prompt "Power Menu")

case "$chosen" in
"  Lock")
  niri msg action lock
  ;;
"  Reboot")
  systemctl reboot
  ;;
"󰗼  Logout")
  niri msg action quit -s
  ;;
"  Shutdown")
  systemctl poweroff
  ;;
"⏾  Suspend")
  systemctl suspend
  ;;
*) ;;
esac
