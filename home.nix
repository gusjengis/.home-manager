{
  config,
  pkgs,
  lib,
  ...
}:
let
  hmUpdateOnReady = pkgs.writeShellScript "hm-update-on-ready" ''
    set -euo pipefail

    export PATH="${config.home.profileDirectory}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin"

    boot_id="$(${pkgs.coreutils}/bin/cat /proc/sys/kernel/random/boot_id)"
    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$UID}"
    stamp="$runtime_dir/hm-update-$boot_id.done"
    [ -e "$stamp" ] && exit 0

    if command -v hyprctl >/dev/null 2>&1; then
      waited=0
      timeout="''${HM_HYPR_WAIT_TIMEOUT:-180}"
      until hyprctl -j instances >/dev/null 2>&1; do
        if [ "$waited" -ge "$timeout" ]; then
          break
        fi
        ${pkgs.coreutils}/bin/sleep 2
        waited=$((waited + 2))
      done
    fi

    until ${pkgs.networkmanager}/bin/nm-online -q --timeout=5 >/dev/null 2>&1 || ${pkgs.wget}/bin/wget -q --spider --timeout=5 https://github.com; do
      ${pkgs.coreutils}/bin/sleep 10
    done

    if command -v dunstify >/dev/null 2>&1; then
      waited=0
      timeout="''${HM_NOTIFY_WAIT_TIMEOUT:-120}"
      while [ "$waited" -lt "$timeout" ]; do
        has_owner="$(${pkgs.glib}/bin/gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.NameHasOwner org.freedesktop.Notifications 2>/dev/null || true)"
        case "$has_owner" in
          *true*)
            break
            ;;
        esac
        ${pkgs.coreutils}/bin/sleep 2
        waited=$((waited + 2))
      done
    fi

    ${pkgs.coreutils}/bin/touch "$stamp"
    exec ${pkgs.bash}/bin/bash "$HOME/.home-manager/scripts/update.sh"
  '';
in
{
  imports = [
    ./desktop_env/mod.nix
    ./modules/mod.nix
    ./programs/mod.nix
    ./utilities/mod.nix
    ./create_directories.nix
    ./link_files.nix
  ]
  ++ lib.optional (builtins.pathExists /home/gusjengis/.home-manager/modules.nix) /home/gusjengis/.home-manager/modules.nix
  ++ lib.optional (builtins.pathExists /home/gusjengis/.home-manager/local.nix) /home/gusjengis/.home-manager/local.nix;

  options.desktopEnv.enable = lib.mkEnableOption "desktop environment packages" // {
    default = true;
  };

  options.dev.enable = lib.mkEnableOption "dev tools and repos" // {
    default = true;
  };

  options.laptop.enable = lib.mkEnableOption "is a laptop" // {
    default = true;
  };

  config = lib.mkMerge [
    {
      programs.home-manager.enable = true;

      home.username = "gusjengis";
      home.homeDirectory = "/home/gusjengis";

      home.stateVersion = "25.05";

      home.sessionVariables = {
        SYNC_REPO_GROUPS = if config.dev.enable then "core,dev" else "core";
      };

      nixpkgs.config.allowUnfree = true;

      systemd.user.services.hm-update-on-first-network = {
        Unit = {
          Description = "Run home update after first network availability";
          After = [
            "default.target"
            "network-online.target"
          ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash ${hmUpdateOnReady}";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    }

    (lib.mkIf config.desktopEnv.enable {
      home.sessionVariables = {
        LD_LIBRARY_PATH = /run/opengl-driver/lib;
      };

      services.flatpak = {
        enable = true;

        remotes = [
          {
            name = "flathub";
            location = "https://flathub.org/repo/flathub.flatpakrepo";
          }
        ];

        packages = [
          "com.bambulab.BambuStudio"
        ];
      };
    })
  ];

}
