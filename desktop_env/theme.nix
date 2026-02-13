{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.desktopEnv.enable {
    home.sessionVariables = {
      GTK_THEME = "Adwaita:dark";
      QT_STYLE_OVERRIDE = "kvantum";
      QT_QPA_PLATFORMTHEME = "qt5ct";
    };

    gtk = {
      enable = true;
      theme.name = "Adwaita-dark";
      theme.package = pkgs.gnome-themes-extra;
    };

    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=KvAdaptaDark
    '';
  };
}
