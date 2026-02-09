{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.home-manager.enable = true;

  imports = [
    ./desktop_env/mod.nix
    ./programs/mod.nix
    ./utilities/mod.nix
    ./create_directories.nix
    ./link_files.nix
  ];

  home.username = "gusjengis";
  home.homeDirectory = "/home/gusjengis";

  home.stateVersion = "25.05";

  home.sessionVariables = {
    LD_LIBRARY_PATH = /run/opengl-driver/lib;
  };

  nixpkgs.config.allowUnfree = true;

  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "com.bambulab.BambuStudio"
    ];
  };
}
