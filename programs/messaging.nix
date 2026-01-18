{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    wireplumber
    zoom-us
  ];
}
