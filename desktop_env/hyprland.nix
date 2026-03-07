{
  config,
  pkgs,
  lib,
  Mac,
  PC,
  hyprlog-nixpkgs,
  ...
}:

{

  config = lib.mkIf config.desktopEnv.enable {
    home.packages =
      with pkgs;
      [
        # hyprsunset
        hypridle
        hyprpaper
        dunst
        libnotify
        linux-wallpaperengine
        # hyprlog-nixpkgs.hyprlog
        swww
        eww
        wofi
        font-awesome
        wallust
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ]
      ++ lib.optionals PC [
        vial
      ];

    home.file.".cache/theme/wofi-accent.css".text = ''
      @define-color accent #58a6ff;
      @define-color accent_soft rgba(88, 166, 255, 0.22);
    '';

    home.file.".config/waybar/config.json".source = ../config_files/waybar/config.json;
    home.file.".config/waybar/style.css".source = ../config_files/waybar/style.css;

    home.activation.macHyprSetup = lib.mkIf Mac (
      lib.hm.dag.entryAfter [ "symlink" ] ''
        ln -sf $HOME/.home-manager/config_files/hypr/appearance.mac.conf $HOME/.config/hypr/appearance.conf
        ln -sf $HOME/.home-manager/config_files/hypr/variables.mac.conf $HOME/.config/hypr/platform-variables.conf
      ''
    );

    home.activation.pcHyprSetup = lib.mkIf PC (
      lib.hm.dag.entryAfter [ "symlink" ] ''
        ln -sf $HOME/.home-manager/config_files/hypr/appearance.pc.conf $HOME/.config/hypr/appearance.conf
        ln -sf $HOME/.home-manager/config_files/hypr/variables.pc.conf $HOME/.config/hypr/platform-variables.conf
      ''
    );
  };
}
