{ config, pkgs, ... }:

let
  theme = builtins.readFile ~/.dotfiles/user/config_files/hypr/theme.conf;
  themeLines = pkgs.lib.splitString "\n" theme;
  prefix = "$wallpaper = ";
  wallpaperLine = builtins.head (builtins.filter
    (line: builtins.substring 0 (builtins.stringLength prefix) line == prefix)
    themeLines
  );
  wallpaper = builtins.substring (builtins.stringLength prefix)
    (builtins.stringLength wallpaperLine - builtins.stringLength prefix)
    wallpaperLine;
in
{
  home.packages = with pkgs; [ hyprpaper ];

  # Write out the final hyprpaper.conf using the substituted wallpaper value.
  home.file.".config/hypr/hyprpaper.conf".text = ''
    preload = ${wallpaper}
    wallpaper = , ${wallpaper}
  '';
}
