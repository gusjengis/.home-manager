{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home.activation.symlinkHyprlandConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf $HOME/.home-manager/config_files/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf
  '';
}
