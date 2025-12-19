# https://copr.fedorainfracloud.org/coprs/solopasha/hyprland
# https://copr.fedorainfracloud.org/coprs/scottames/ghostty/
# https://copr.fedorainfracloud.org/coprs/jkinred/satty

# Download the .repo file. there is a download link for YOUR release
# Copy to yum.repos.d:

# rpm-ostree refresh-md

rpm-ostree install \
  hyprland waybar xdg-desktop-portal-hyprland hyprpaper hyprlock hypridle \
  hyprland-qtutils hyprpicker xdg-terminal-exec ghostty wofi pavucontrol \
  playerctl wiremix slurp grim satty wlr-randr mako \
  imv fontawesome-fonts-all fastfetch blueman niri
