{
  config,
  pkgs,
  stable,
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
      plasticscm
      stable.roslyn-ls
      verco
    ];
}
