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
    ]
    ++ lib.optionals PC [ easyeffects ];
}
