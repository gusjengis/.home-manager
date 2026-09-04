{
  config,
  pkgs,
  stable,
  lib,
  PC,
  ...
}:

{
  options.gameDev.enable = lib.mkEnableOption "game development tools" // {
    default = false;
  };

  config = lib.mkIf (config.gameDev.enable && config.desktopEnv.enable) {
    home.packages =
      with pkgs;
      [
      ]
      ++ lib.optionals PC [
        # vscode
        # unityhub
        # blender
        # plasticscm-client-complete
        # dotnetCorePackages.dotnet_9.sdk
        # stable.roslyn-ls
        # cudaPackages.cudatoolkit
      ];
  };
}
