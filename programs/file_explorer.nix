{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nautilus
    kdePackages.dolphin
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
