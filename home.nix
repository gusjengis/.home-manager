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
    ./secrets.nix
  ];

  home.username = "gusjengis";
  home.homeDirectory = "/home/gusjengis";

  home.stateVersion = "25.05";

  programs.git = {
    enable = true;
    userName = "gusjengis";
    userEmail = "anthony.j.green@outlook.com";
    extraConfig = {
      credential.helper = "store";
    };
  };

  home.sessionVariables = {
    LD_LIBRARY_PATH = /run/opengl-driver/lib;
    ANTHROPIC_API_KEY = config.secrets.anthropicApiKey;
  };

  nixpkgs.config.allowUnfree = true;
  waybar.enable = true;
}
