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
    [
      python314
    ]
    ++ lib.optionals PC [
      unityhub
      plasticscm
      stable.roslyn-ls
      stable.alvr
      cudaPackages.cudatoolkit
      cudaPackages.cuda_nvcc
    ];
}
