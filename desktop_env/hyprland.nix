{
  config,
  pkgs,
  lib,
  inputs,
  Mac,
  PC,
  hyprlog-nixpkgs,
  ...
}:

{

  home.packages = with pkgs; [
    hyprsunset
    hypridle
    dunst
    libnotify
    linux-wallpaperengine
    hyprlog-nixpkgs.hyprlog
    jq
    eww
  ];

  home.activation.symlinkTmuxConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/dunst

    ln -sf $HOME/.home-manager/config_files/dunst/dunstrc $HOME/.config/dunst/dunstrc

    mkdir -p ~/.config/hypr

    ln -sf $HOME/.home-manager/config_files/hypr/autostart.conf $HOME/.config/hypr/autostart.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprlog.conf $HOME/.config/hypr/hyprlog.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hypridle.conf $HOME/.config/hypr/hypridle.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprland.conf $HOME/.config/hypr/hyprland.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprpaper.conf $HOME/.config/hypr/hyprpaper.conf
    ln -sf $HOME/.home-manager/config_files/hypr/hyprsunset.conf $HOME/.config/hypr/hyprsunset.conf
    ln -sf $HOME/.home-manager/config_files/hypr/keybinds.conf $HOME/.config/hypr/keybinds.conf
    ln -sf $HOME/.home-manager/config_files/hypr/workspaces.conf $HOME/.config/hypr/workspaces.conf
    ln -sf $HOME/.home-manager/config_files/hypr/variables.conf $HOME/.config/hypr/variables.conf

    mkdir -p ~/.config/hypr/scripts
    ln -sf $HOME/.home-manager/config_files/hypr/scripts/which-key.sh $HOME/.config/hypr/scripts/which-key.sh
    mkdir -p ~/.config/eww-which-key
    ln -sf $HOME/.home-manager/config_files/eww-which-key/eww.scss $HOME/.config/eww-which-key/eww.scss
    ln -sf $HOME/.home-manager/config_files/eww-which-key/eww.yuck $HOME/.config/eww-which-key/eww.yuck
    ln -sf $HOME/.home-manager/wallpapers/ $HOME/Wallpapers
  '';

  home.activation.macHyprSetup = lib.mkIf Mac (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf $HOME/.home-manager/config_files/hypr/appearance.mac.conf $HOME/.config/hypr/appearance.conf
      ln -sf $HOME/.home-manager/config_files/hypr/variables.mac.conf $HOME/.config/hypr/platform-variables.conf
      ln -sf $HOME/.home-manager/config_files/hypr/monitors.mac.conf $HOME/.config/hypr/monitors.conf
    ''
  );

  home.activation.pcHyprSetup = lib.mkIf PC (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sf $HOME/.home-manager/config_files/hypr/appearance.pc.conf $HOME/.config/hypr/appearance.conf
      ln -sf $HOME/.home-manager/config_files/hypr/variables.pc.conf $HOME/.config/hypr/platform-variables.conf
      ln -sf $HOME/.home-manager/config_files/hypr/monitors.pc.conf $HOME/.config/hypr/monitors.conf
    ''
  );
}
