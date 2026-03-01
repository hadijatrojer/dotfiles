#!/usr/bin/env bash
set -euo pipefail

# Toggle the layout on the current active workspace between dwindle and scrolling.
active_workspace="$(hyprctl activeworkspace -j | jq -r '.id')"
current_layout="$(hyprctl activeworkspace -j | jq -r '.tiledLayout')"

case "$current_layout" in
dwindle) new_layout="scrolling" ;;
*) new_layout="dwindle" ;;
esac

hyprctl keyword workspace "$active_workspace, layout:$new_layout"
notify-send "Workspace layout set to $new_layout"
