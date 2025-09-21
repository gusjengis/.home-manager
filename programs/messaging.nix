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
      zoom-us
    ]
    ++ lib.optionals PC [
      #discord-canary
      #slack
    ];
}
