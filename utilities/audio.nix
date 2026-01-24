{
  config,
  pkgs,
  PC,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      pavucontrol
      playerctl
    ]
    ++ lib.optionals PC [ easyeffects ];
}
