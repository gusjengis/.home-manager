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
        nmgui
        wallust
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ]
      ++ lib.optionals PC [
        vial
      ];

    home.activation.ensureAccentCacheFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/.cache/theme"
            if [ -L "$HOME/.cache/theme/wofi-accent.css" ]; then
              rm -f "$HOME/.cache/theme/wofi-accent.css"
            fi
            if [ ! -f "$HOME/.cache/theme/wofi-accent.css" ]; then
              cat > "$HOME/.cache/theme/wofi-accent.css" <<'EOF'
      @define-color accent #58a6ff;
      @define-color accent_soft rgba(88, 166, 255, 0.22);
      EOF
            fi
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
