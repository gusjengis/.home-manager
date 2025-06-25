{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    unityhub
    plasticscm
  ];
}
