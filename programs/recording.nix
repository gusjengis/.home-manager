{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    obs-studio
    audacity
  ];
}
