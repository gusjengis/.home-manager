{ config, pkgs, alga, ... }:

{
  home.packages = with pkgs; [
    alga
  ];
}
