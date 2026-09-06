{
  config,
  pkgs,
  stable,
  PC,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      openssl
    ]
    ++ lib.optionals config.dev.enable [
      cloc
    ]
    ++ lib.optionals config.desktopEnv.enable [
      handy
      wtype
      xdotool
      gource
    ]
    ++ lib.optionals (PC && config.desktopEnv.enable) [
      lmstudio
    ]
    ++ lib.optionals (config.dev.enable && config.desktopEnv.enable) [
      oxker
      posting
      android-tools
      zulu17
    ]
    ++ lib.optionals (PC && config.dev.enable && config.desktopEnv.enable) [
      arduino
      android-studio
    ];
}
