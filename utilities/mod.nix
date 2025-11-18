{
  config,
  pkgs,
  Mac,
  lib,
  ...
}:

{
  imports = [
    ./bluetooth.nix
    ./git.nix
    ./screenshots.nix
    ./audio.nix
    ./disk.nix
    ./lg_tv.nix
    ./tmux.nix
  ];
  home.packages =
    with pkgs;
    [
      btop
      zip
      unzip
      usbutils
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      wget
    ]
    ++ lib.optionals Mac [ acpi ];
}
