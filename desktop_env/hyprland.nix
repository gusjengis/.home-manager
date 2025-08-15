{
  config,
  pkgs,
  unstable,
  lib,
  inputs,
  ...
}:

{

  home.packages = with pkgs; [
    unstable.hyprsunset
    hypridle
  ];

  home.activation.symlinkHyprlandConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf $HOME/.home-manager/config_files/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprsunset.conf $HOME/.config/hypr/hyprsunset.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hypridle.conf $HOME/.config/hypr/hypridle.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprfocus.conf $HOME/.config/hypr/hyprfocus.conf
    ln -sf $HOME/.home-manager/config_files/dunst/dunstrc $HOME/.config/dunst/dunstrc
  '';
}
