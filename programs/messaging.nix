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
      presenterm
    ]
    ++ lib.optionals PC [
      #discord-canary
      #slack
    ];
}
