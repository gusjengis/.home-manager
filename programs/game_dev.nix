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
    [ ]
    ++ lib.optionals PC [
      unityhub
      # plasticscm
      verco
    ];
}
