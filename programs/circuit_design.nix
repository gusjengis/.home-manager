{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    kicad
    ngspice
  ];
}
