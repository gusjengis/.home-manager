{ config, pkgs, ... }:

{
  imports = [
    ./idle.nix
    ./hyprland.nix
    ./cursor.nix
    ./wallpaper.nix
    ./app_launcher.nix
    ./theme.nix
    # ./lock_screen.nix
  ];
}
