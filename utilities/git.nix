{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ gh ];

  programs.git = {
    enable = true;
    userName = "gusjengis";
    userEmail = "anthony.j.green@outlook.com";
    extraConfig = { credential.helper = "store"; };
  };
}
