{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.gaming.enable = lib.mkEnableOption "gaming tools";

  config = lib.mkIf (config.gaming.enable && config.desktopEnv.enable) {
    home.packages = with pkgs; [
      protonup-qt
      zulu8
      prismlauncher
      atlauncher
    ];
  };
}
