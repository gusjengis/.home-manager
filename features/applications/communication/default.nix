{
  config,
  pkgs,
  lib,
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
    # No aarch64 builds. The Hyprland keybinds fall back to the webapp
    # launchers where these are missing; see the hyprland feature's
    # platform-variables selection.
    ++ lib.optionals (pkgs.stdenv.hostPlatform.isx86_64 && config.desktopEnv.enable) [
      zoom-us
      discord-canary
      slack
    ];

  # KDE Connect needs one-time pairing after first installation.
}
