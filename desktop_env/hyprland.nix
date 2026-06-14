{
  config,
  pkgs,
  lib,
  Mac,
  PC,
  inputs,
  hyprlog-nixpkgs,
  ...
}:

let
  phosphorIcons = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "ttf-phosphor-icons";
    version = "2.1.2";

    src = pkgs.fetchzip {
      url = "https://github.com/phosphor-icons/web/archive/refs/tags/v${version}.zip";
      sha256 = "sha256-96ivFjm0cBhqDKNB50klM7D3fevt8X9Zzm82KkJKMtU=";
      stripRoot = true;
    };

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm644 src/*/*.ttf -t $out/share/fonts/truetype
      install -Dm644 LICENSE -t $out/share/licenses/${pname}
      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "A flexible icon family for interfaces, diagrams, presentations";
      homepage = "https://phosphoricons.com";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  ambxstPackage =
    let
      system = pkgs.stdenv.hostPlatform.system;
      quickshellPkg = inputs.ambxst.inputs.quickshell.packages.${system}.default.override {
        xorg = {
          libxcb = pkgs.libxcb;
        };
      };

      baseEnv =
        with pkgs;
        [
          quickshellPkg
          mesa
          libglvnd
          egl-wayland
          wayland
          qt6.qtbase
          qt6.qtsvg
          qt6.qttools
          qt6.qtwayland
          qt6.qtdeclarative
          qt6.qtimageformats
          kdePackages.qtmultimedia
          kdePackages.qtshadertools
          kdePackages.syntax-highlighting
          brightnessctl
          ddcutil
          fontconfig
          glib
          grim
          imagemagick
          jq
          litellm
          libnotify
          matugen
          power-profiles-daemon
          slurp
          sqlite
          upower
          wl-clip-persist
          wl-clipboard
          wlsunset
          wtype
          zbar
          zenity
          inetutils
          adw-gtk3
          mpvpaper
          ffmpeg
          x264
          playerctl
          pipewire
          wireplumber
          kitty
          tmux
          fuzzel
          networkmanagerapplet
          blueman
          pwvucontrol
          easyeffects
          gradia
          kdePackages.breeze-icons
          hicolor-icon-theme
          roboto
          roboto-mono
          league-gothic
          terminus_font
          terminus_font_ttf
          dejavu_fonts
          liberation_ttf
          nerd-fonts.iosevka
          nerd-fonts.symbols-only
          noto-fonts
          noto-fonts-color-emoji
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          phosphorIcons
          (tesseract.override {
            enableLanguages = [
              "eng"
              "spa"
              "lat"
              "jpn"
              "chi_sim"
              "chi_tra"
              "kor"
            ];
          })
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [ gpu-screen-recorder ];

      envAmbxst = pkgs.buildEnv {
        name = "Ambxst-env";
        paths = baseEnv;
        pathsToLink = [
          "/lib/qt-6/qml"
        ];
      };

      shellSrc = pkgs.stdenv.mkDerivation {
        pname = "ambxst-shell";
        version = lib.removeSuffix "\n" (builtins.readFile "${inputs.ambxst}/version");
        src = lib.cleanSource inputs.ambxst;
        dontBuild = true;

        installPhase = ''
          mkdir -p $out
          cp -r . $out/
        '';
      };

      launcher = pkgs.writeShellScriptBin "ambxst" ''
        export AMBXST_QS="${quickshellPkg}/bin/qs"
        export PATH="${lib.makeBinPath (baseEnv ++ [ pkgs.python3 ])}:$PATH"
        export QML2_IMPORT_PATH="${envAmbxst}/lib/qt-6/qml:$QML2_IMPORT_PATH"
        export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
        exec ${shellSrc}/cli.sh "$@"
      '';
    in
    pkgs.buildEnv {
      name = "Ambxst";
      paths = [
        envAmbxst
        launcher
      ];
      meta.mainProgram = "ambxst";
    };
in
{

  config = lib.mkIf config.desktopEnv.enable {
    home.packages =
      with pkgs;
      [
        # hyprsunset
        hypridle
        hyprpaper
        # dunst
        libnotify
        linux-wallpaperengine
        # hyprlog-nixpkgs.hyprlog
        awww
        eww
        wofi
        font-awesome
        nerd-fonts.iosevka
        nerd-fonts.symbols-only
        # nmgui
        wallust
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        ambxstPackage
      ]
      ++ [ phosphorIcons ]
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

    home.activation.macHyprSetup = lib.mkIf Mac (
      lib.hm.dag.entryAfter [ "symlink" ] ''
        ln -sf $HOME/.home-manager/config_files/hypr/appearance.mac.conf $HOME/.config/hypr/appearance.conf
        ln -sf $HOME/.home-manager/config_files/hypr/variables.mac.conf $HOME/.config/hypr/platform-variables.conf
        ln -sf $HOME/.home-manager/config_files/hypr/appearance.mac.lua $HOME/.config/hypr/appearance.lua
        ln -sf $HOME/.home-manager/config_files/hypr/variables.mac.lua $HOME/.config/hypr/platform-variables.lua
      ''
    );

    home.activation.pcHyprSetup = lib.mkIf PC (
      lib.hm.dag.entryAfter [ "symlink" ] ''
        ln -sf $HOME/.home-manager/config_files/hypr/appearance.pc.conf $HOME/.config/hypr/appearance.conf
        ln -sf $HOME/.home-manager/config_files/hypr/variables.pc.conf $HOME/.config/hypr/platform-variables.conf
        ln -sf $HOME/.home-manager/config_files/hypr/appearance.pc.lua $HOME/.config/hypr/appearance.lua
        ln -sf $HOME/.home-manager/config_files/hypr/variables.pc.lua $HOME/.config/hypr/platform-variables.lua
      ''
    );

    home.activation.hyprLuaSetup = lib.hm.dag.entryAfter [ "symlink" ] ''
      mkdir -p $HOME/.config/hypr
      # ln -sf $HOME/.home-manager/config_files/hypr/hyprland.lua $HOME/.config/hypr/hyprland.lua
      ln -sf $HOME/.home-manager/config_files/hypr/autostart.lua $HOME/.config/hypr/autostart.lua
      ln -sf $HOME/.home-manager/config_files/hypr/keybinds.lua $HOME/.config/hypr/keybinds.lua
      ln -sf $HOME/.home-manager/config_files/hypr/monitors.lua $HOME/.config/hypr/monitors.lua
      ln -sf $HOME/.home-manager/config_files/hypr/workspaces.lua $HOME/.config/hypr/workspaces.lua
      ln -sf $HOME/.home-manager/config_files/hypr/variables.lua $HOME/.config/hypr/variables.lua
      ln -sf $HOME/.home-manager/config_files/hypr/hyprfocus.lua $HOME/.config/hypr/hyprfocus.lua
      ln -sf $HOME/.home-manager/config_files/hypr/hypridle.lua $HOME/.config/hypr/hypridle.lua
      ln -sf $HOME/.home-manager/config_files/hypr/hyprlog.lua $HOME/.config/hypr/hyprlog.lua
      ln -sf $HOME/.home-manager/config_files/hypr/hyprpaper.lua $HOME/.config/hypr/hyprpaper.lua
      ln -sf $HOME/.home-manager/config_files/hypr/hyprsunset.lua $HOME/.config/hypr/hyprsunset.lua
    '';
  };
}
