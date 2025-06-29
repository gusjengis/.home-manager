{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [ hyprpaper ];

  home.activation.symlinkHyprpaperConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sf $HOME/.home-manager/config_files/hypr/hyprpaper.conf $HOME/.config/hypr/hyprpaper.conf
  '';
}
