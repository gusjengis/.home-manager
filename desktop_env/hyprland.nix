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
    hyprpaper
    dunst
    libnotify
    linux-wallpaperengine
    # hyprlog-nixpkgs.hyprlog
    jq
    eww
    wofi
    waybar
    font-awesome
  ];

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
