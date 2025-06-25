{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ hyprshot grim slurp ];
}
