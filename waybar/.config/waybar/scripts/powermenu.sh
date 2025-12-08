#!/bin/bash

chosen=$(echo -e "  Lock\n  Reboot\n󰗼  Logout\n  Shutdown\n⏾  Suspend" | wofi --dmenu --i --width 240 --height 320 --prompt "Power Menu")

case "$chosen" in
    "  Lock")
        ~/.config/sway/lock.sh
        ;;
    "  Reboot")
        systemctl reboot
        ;;
    "󰗼  Logout")
        swaymsg exit
        ;;
    "  Shutdown")
        systemctl poweroff
        ;;
    "⏾  Suspend")
        systemctl suspend
        ;;
    *)
        ;;
esac
