{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    #!mac    discord-canary
    #!mac       slack
    wireplumber
    libsForQt5.xwaylandvideobridge
  ];
}
