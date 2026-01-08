{ config, pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./cursor.nix
    ./theme.nix
  ];

  home.packages = with pkgs; [
    swww
  ];
}
