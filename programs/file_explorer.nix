{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar
    xfce.tumbler
    xfce.thunar-volman
    xfce.thunar-archive-plugin
    file-roller
    gvfs
    qimgv
    udiskie
  ];
}
