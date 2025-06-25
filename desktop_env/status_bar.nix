{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ waybar ];

  home.file.".config/waybar/config".source = ../config_files/waybar/config;
  home.file.".config/waybar/config.json".source =
    ../config_files/waybar/config.jsonc;
  home.file.".config/waybar/style.css".source =
    ../config_files/waybar/style.css;
}
