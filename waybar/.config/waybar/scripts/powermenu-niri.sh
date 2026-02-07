#!/bin/bash

chosen=$(echo -e "  Lock\n  Reboot\n󰗼  Logout\n  Shutdown\n⏾  Suspend" | fuzzel --dmenu --prompt "Power Menu " --lines 5 --width 20)

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
