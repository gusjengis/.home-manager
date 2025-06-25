{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ discord-canary slack wireplumber libsForQt5.xwaylandvideobridge ];
}
