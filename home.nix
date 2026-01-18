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
    ./repos/repos.nix
    ./nvim/mod.nix
  ];

  home.username = "dragonflylane";
  home.homeDirectory = "/home/dragonflylane";

  home.stateVersion = "25.05";

  home.sessionVariables = {
    LD_LIBRARY_PATH = /run/opengl-driver/lib;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config = {
    permittedInsecurePackages = [
      "mbedtls-2.28.10" # not sure what program needs this
    ];
  };
}
