{
  config,
  pkgs,
  lib,
  unstable,
  ...
}:

{
  home.packages = with pkgs; [
    # obs-studio
    # audacity
    # unstable.sunshine
  ];
}
