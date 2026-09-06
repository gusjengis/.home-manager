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
      # TODO: belong in a phone sync/connection folder, not generally used for communication
      scrcpy
      kdePackages.kdeconnect-kde
      kdePackages.kpeople

      mailspring
    ]
    ++ lib.optionals (PC && config.desktopEnv.enable) [
      zoom-us
      discord-canary
      slack
    ];

  # KDE Connect needs one-time pairing after first installation.
}
