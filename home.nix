{
  config,
  pkgs,
  lib,
  ...
}:
let
  helveticaNeueLtStd = pkgs.stdenvNoCC.mkDerivation {
    pname = "helvetica-neue-lt-std";
    version = "2014.08.16";
    src = ./fonts/helvetica-neue-lt-std;

    dontUnpack = true;

    installPhase = ''
      install -Dm644 "$src"/*.otf -t $out/share/fonts/opentype
    '';
  };
in
{
  imports = [
    ./desktop_env/mod.nix
    ./features
    ./legacy/ambxst
    ./modules/mod.nix
    ./policy/insecure-packages.nix
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

      fonts.fontconfig.enable = true;

      home.packages = [ helveticaNeueLtStd ];

      nixpkgs.config.allowUnfree = true;
    }

    (lib.mkIf config.desktopEnv.enable {
      home.sessionVariables = {
        LD_LIBRARY_PATH = /run/opengl-driver/lib;
      };
    })
  ];

}
