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
    ]
    ++ lib.optionals PC [
      #discord-canary
      #slack
    ];
}
