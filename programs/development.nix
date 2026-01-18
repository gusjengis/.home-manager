{
  config,
  pkgs,
  stable,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    zathura
  ];
}
