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
    ]
    ++ lib.optionals PC [
      zoom-us
      #discord-canary
      #slack
    ];
}
