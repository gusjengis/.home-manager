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

    if command -v notify-send >/dev/null 2>&1; then
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
