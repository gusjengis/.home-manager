{ config, pkgs, ... }:

{
  home.sessionVariables = {
    # Tells apps that prefer GTK what theme variant to use
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE =
      "kvantum"; # Use Kvantum for better dark theme support on Qt
    QT_QPA_PLATFORMTHEME =
      "qt5ct"; # So you can control themes via qt5ct if needed
  };

  # Set GTK theme
  gtk = {
    enable = true;
    theme.name = "Adwaita-dark";
    theme.package = pkgs.gnome-themes-extra;
  };

  # Set cursor and icon themes too, optionally
  # qt.enable = true;  # Only if using Qt

  # Optionally use a dark Kvantum theme for Qt
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=KvAdaptaDark
  '';
}
