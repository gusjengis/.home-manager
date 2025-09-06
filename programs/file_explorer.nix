{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    xfce.thunar
    xfce.tumbler
    xfce.thunar-volman
    gvfs
    qimgv
    file-roller
    udiskie
  ];
}
