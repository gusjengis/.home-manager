{
  config,
  pkgs,
  lib,
  Mac,
  PC,
  ...
}:

{
  config = lib.mkIf config.desktopEnv.enable {
    home.packages =
      with pkgs;
      [
        hypridle
        hyprpaper
        libnotify
        linux-wallpaperengine
        awww
        wofi
        font-awesome
        nerd-fonts.iosevka
        nerd-fonts.symbols-only
        wallust
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ]
      ++ lib.optionals PC [ vial ];

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

    home.activation.macHyprSetup = lib.mkIf Mac (
      lib.hm.dag.entryAfter [ "symlink" ] ''
        ln -sf $HOME/.home-manager/config_files/hypr/variables.mac.lua $HOME/.config/hypr/platform-variables.lua
      ''
    );

    home.activation.pcHyprSetup = lib.mkIf PC (
      lib.hm.dag.entryAfter [ "symlink" ] ''
        ln -sf $HOME/.home-manager/config_files/hypr/variables.pc.lua $HOME/.config/hypr/platform-variables.lua
      ''
    );
  };
}
