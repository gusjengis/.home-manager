{ config, pkgs, ... }:

{
  imports = [
    ./idle.nix
    ./hyprland.nix
    ./cursor.nix
    ./theme.nix
    # ./lock_screen.nix
  ];
}
