{
  config,
  pkgs,
  lib,
  inputs,
  Mac,
  PC,
  ...
}:

{

  home.packages = with pkgs; [
    hyprsunset
    hypridle
    dunst
    libnotify
    linux-wallpaperengine
  ];

  home.activation.symlinkTmuxConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/dunst

    ln -sf $HOME/.home-manager/config_files/dunst/dunstrc $HOME/.config/dunst/dunstrc

    mkdir -p ~/.config/hypr

    ln -sf $HOME/.home-manager/config_files/hypr/autostart.conf $HOME/.config/hypr/autostart.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprfocus.conf $HOME/.config/hypr/hyprfocus.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hypridle.conf $HOME/.config/hypr/hypridle.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprpaper.conf $HOME/.config/hypr/hyprpaper.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprsunset.conf $HOME/.config/hypr/hyprsunset.conf
    ln -sf $HOME/.home-manager/config_files/hypr/keybinds.conf $HOME/.config/hypr/keybinds.conf
    ln -sf $HOME/.home-manager/config_files/hypr/shutdown.conf $HOME/.config/hypr/shutdown.conf
    ln -sf $HOME/.home-manager/config_files/hypr/workspaces.conf $HOME/.config/hypr/workspaces.conf
  '';

  home.activation.macHyprSetup = lib.mkIf Mac (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf $HOME/.home-manager/config_files/hypr/appearance.mac.conf $HOME/.config/hypr/appearance.conf
      ln -sf $HOME/.home-manager/config_files/hypr/variables.mac.conf $HOME/.config/hypr/variables.conf
      ln -sf $HOME/.home-manager/config_files/hypr/monitors.mac.conf $HOME/.config/hypr/monitors.conf
    ''
  );

  home.activation.pcHyprSetup = lib.mkIf PC (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf $HOME/.home-manager/config_files/hypr/appearance.pc.conf $HOME/.config/hypr/appearance.conf
      ln -sf $HOME/.home-manager/config_files/hypr/variables.pc.conf $HOME/.config/hypr/variables.conf
      ln -sf $HOME/.home-manager/config_files/hypr/monitors.pc.conf $HOME/.config/hypr/monitors.conf
    ''
  );
}
