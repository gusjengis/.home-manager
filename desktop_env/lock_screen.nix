{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ hyprlock ];

  home.file.".config/hypr/hyprlock.conf".source =
    ../config_files/hypr/hyprlock.conf;
  home.file.".config/hypr/hyprlock.conf".force = true;
}
