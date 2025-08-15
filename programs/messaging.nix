{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    discord-canary
    slack
    whatsie
    wireplumber
    libsForQt5.xwaylandvideobridge
  ];
}
