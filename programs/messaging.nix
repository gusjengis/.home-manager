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
      gurk-rs
      wireplumber
      kdePackages.xwaylandvideobridge
      signal-desktop
      presenterm
      kdePackages.kdeconnect-kde
      kdePackages.kpeople
      scrcpy
      android-tools
    ]
    ++ lib.optionals PC [
      zoom-us
      discord-canary
      slack
    ];
}
