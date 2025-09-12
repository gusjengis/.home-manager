{
  config,
  pkgs,
  stable,
  lib,
  PC,
  plasticscm,
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
