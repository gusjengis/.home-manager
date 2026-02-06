{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ gh ];

  programs.git = {
    enable = true;
    settings = {
      credential.helper = "store";
      user = {
        name = "gusjengis";
        email = "anthony.j.green@outlook.com";
      };
    };
    lfs.enable = true;
  };
}
