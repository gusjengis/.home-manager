{ config, pkgs, ... }:
let
  CURSOR_PKG = pkgs.apple-cursor;
  CURSOR_THEME = "macOS";
  CURSOR_SIZE = 24;
in
{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = CURSOR_THEME;
    package = CURSOR_PKG;
    size = CURSOR_SIZE;
  };

  # Apply to GTK applications
  gtk.cursorTheme = {
    name = CURSOR_THEME;
    package = CURSOR_PKG;
    size = CURSOR_SIZE;
  };

  # Apply settings immediately
  home.sessionVariables = {
    XCURSOR_THEME = CURSOR_THEME;
    XCURSOR_SIZE = "${toString CURSOR_SIZE}";
  };

  home.packages = with pkgs; [ wl-kbptr ];
}
