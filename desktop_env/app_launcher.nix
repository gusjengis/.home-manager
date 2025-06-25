{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ wofi ];

  home.file.".config/wofi/config".source = ../config_files/wofi/config;
  home.file.".config/wofi/style.css".source = ../config_files/wofi/style.css;
}
