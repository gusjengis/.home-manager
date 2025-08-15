{ config, pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./cursor.nix
    ./theme.nix
    # ./lock_screen.nix
  ];
}
