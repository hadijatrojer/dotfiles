# https://copr.fedorainfracloud.org/coprs/acidburnmonkey/hyprland/
# https://copr.fedorainfracloud.org/coprs/scottames/ghostty/

# Download the .repo file. there is a download link for YOUR release
# Copy to /etc/yum.repos.d:

# rpm-ostree refresh-md

rpm-ostree install \
  hyprland waybar xdg-desktop-portal-hyprland hyprpaper hyprlock hypridle \
  hyprland-guiutils xdg-terminal-exec ghostty wofi playerctl wiremix slurp \
  grim wlr-randr mako imv fontawesome-fonts-all fastfetch blueman niri
