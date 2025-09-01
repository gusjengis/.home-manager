{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    #!mac    discord-canary
    #!mac       slack
    wireplumber
    kdePackages.xwaylandvideobridge
  ];
}
