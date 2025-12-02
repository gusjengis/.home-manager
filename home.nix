{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.home-manager.enable = true;

  imports = [
    ./modules.nix
    ./desktop_env/mod.nix
    ./programs/mod.nix
    ./utilities/mod.nix
    ./directories/mod.nix
    ./repos/mod.nix
    ./nvim/mod.nix
  ];

  home.username = "gusjengis";
  home.homeDirectory = "/home/gusjengis";

  home.stateVersion = "25.05";

  home.sessionVariables = {
    LD_LIBRARY_PATH = /run/opengl-driver/lib;
  };

  nixpkgs.config.allowUnfree = true;
}
