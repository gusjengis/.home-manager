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

  config = lib.mkIf config.gameDev.enable {
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
        stable.roslyn-ls
        cudaPackages.cudatoolkit
        cudaPackages.cuda_nvcc
      ];
  };
}
