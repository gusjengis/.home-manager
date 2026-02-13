{
  config,
  pkgs,
  stable,
  lib,
  PC,
  plasticscm,
  ...
}:

{
  options.gameDev.enable = lib.mkEnableOption "game development tools";

  config = lib.mkIf (config.gameDev.enable && config.desktopEnv.enable) {
    home.packages =
      with pkgs;
      [
        python314
        blender
        vscode
      ]
      ++ lib.optionals PC [
        unityhub
        plasticscm
        dotnetCorePackages.dotnet_9.sdk
        stable.roslyn-ls
        cudaPackages.cudatoolkit
        cudaPackages.cuda_nvcc
      ];
  };
}
