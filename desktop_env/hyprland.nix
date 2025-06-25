{ config, pkgs, lib, ... }:

{
  home.activation.symlinkHyprlandConf = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ln -sf $HOME/.dotfiles/user/config_files/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf
  '';
}
