{
  config,
  pkgs,
  lib,
  PC,
  ...
}:

{
  home.packages =
    with pkgs;
    [
    ]
    ++ lib.optionals config.desktopEnv.enable [
      wireplumber
      signal-desktop
      scrcpy
      kdePackages.kdeconnect-kde
      kdePackages.kpeople
    ]
    ++ lib.optionals (PC && config.desktopEnv.enable) [
      zoom-us
      discord-canary
      slack
    ];
}
