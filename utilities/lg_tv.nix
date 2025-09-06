{
  config,
  pkgs,
  alga,
  PC,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [ ]
    ++ lib.optionals PC [
      alga
    ];
}
