{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [ libreoffice-fresh ];
}
