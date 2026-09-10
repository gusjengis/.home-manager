# Everything every machine shares. Per-machine settings live in hosts/<name>,
# and the roster of machines is hosts/default.nix.
{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:

{
  imports = [
    ./features
    ./legacy/ambxst
    ./policy/insecure-packages.nix
    ./hosts/${hostName}
  ];

  options = {
    host.name = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      description = "Which entry of hosts/ this machine is building.";
    };

    desktopEnv.enable = lib.mkEnableOption "desktop environment packages" // {
      default = true;
    };

    dev.enable = lib.mkEnableOption "dev tools and repos" // {
      default = true;
    };

    laptop.enable = lib.mkEnableOption "is a laptop" // {
      default = true;
    };
  };

  config = lib.mkMerge [
    {
      host.name = hostName;

      programs.home-manager.enable = true;

      home.username = "gusjengis";
      home.homeDirectory = "/home/gusjengis";

      home.stateVersion = "25.05";

      fonts.fontconfig.enable = true;

      home.packages = [ pkgs.helvetica-neue-lt-std ];

      nixpkgs.config.allowUnfree = true;
    }

    (lib.mkIf config.desktopEnv.enable {
      home.sessionVariables = {
        LD_LIBRARY_PATH = /run/opengl-driver/lib;
      };
    })
  ];
}
