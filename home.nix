{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./desktop_env/mod.nix
    ./modules/mod.nix
    ./programs/mod.nix
    ./utilities/mod.nix
    ./create_directories.nix
    ./link_files.nix
  ]
  ++ lib.optional (builtins.pathExists /home/gusjengis/.home-manager/modules.nix) /home/gusjengis/.home-manager/modules.nix
  ++ lib.optional (builtins.pathExists /home/gusjengis/.home-manager/local.nix) /home/gusjengis/.home-manager/local.nix;

  options.desktopEnv.enable = lib.mkEnableOption "desktop environment packages" // {
    default = true;
  };

  options.dev.enable = lib.mkEnableOption "dev tools and repos" // {
    default = true;
  };

  options.laptop.enable = lib.mkEnableOption "is a laptop" // {
    default = true;
  };

  config = lib.mkMerge [
    {
      programs.home-manager.enable = true;

      home.username = "gusjengis";
      home.homeDirectory = "/home/gusjengis";

      home.stateVersion = "25.05";

      home.sessionVariables = {
        SYNC_REPO_GROUPS = if config.dev.enable then "core,dev" else "core";
      };

      nixpkgs.config.allowUnfree = true;
    }

    (lib.mkIf config.desktopEnv.enable {
      home.sessionVariables = {
        LD_LIBRARY_PATH = /run/opengl-driver/lib;
      };

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
    })
  ];

}
