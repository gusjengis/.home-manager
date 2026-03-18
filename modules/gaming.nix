{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.gaming.enable = lib.mkEnableOption "gaming" // {
    default = false;
  };
  config = {
    home.packages =
      (with pkgs; [ moonlight ])
      ++ lib.optionals (config.gaming.enable && config.desktopEnv.enable) (
        with pkgs;
        [
          protonup-qt
          zulu17
          prismlauncher
          atlauncher
          lutris
          solitaire-tui
        ]
      );
  };
}
