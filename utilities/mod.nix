{
  config,
  pkgs,
  lib,
  stable,
  ...
}:

{
  imports = [
    ./bluetooth.nix
    ./git.nix
    ./screenshots.nix
    ./audio.nix
    ./tmux.nix
  ];
  home.packages = with pkgs; [
    btop
    zip
    unzip
    usbutils
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    wget
    # keyd
  ];
}
