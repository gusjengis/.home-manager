{
  config,
  pkgs,
  lib,
  ...
}:

let
  calendarTimelinePython = pkgs.python3.withPackages (
    ps: with ps; [
      google-api-python-client
      google-auth
    ]
  );

  startLargeScreenWaybar = pkgs.writeShellScriptBin "start-large-screen-waybar" ''
    #!/usr/bin/env bash
    set -euo pipefail

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    hypr_dir="$runtime_dir/hypr"

    if [ -d "$hypr_dir" ]; then
      latest_sig="$(ls -1t "$hypr_dir" | head -n 1)"
      if [ -n "$latest_sig" ]; then
        export XDG_RUNTIME_DIR="$runtime_dir"
        export HYPRLAND_INSTANCE_SIGNATURE="$latest_sig"
      fi
    fi

    if command -v pkill >/dev/null 2>&1; then
      pkill -f "$HOME/.home-manager/config_files/hypr/scripts/calendar-eww-service.sh" 2>/dev/null || true
    fi

    export CALENDAR_TIMELINE_PYTHON="${calendarTimelinePython}/bin/python3"
    nohup bash "$HOME/.home-manager/config_files/hypr/scripts/calendar-eww-service.sh" >/tmp/calendar-eww.log 2>&1 &

    exec waybar -c "$HOME/.home-manager/config_files/waybar/config-large-screen.json"
  '';
in
{
  options.largeScreen.enable = lib.mkEnableOption "large screen setup" // {
    default = false;
  };

  config = lib.mkIf (config.largeScreen.enable && config.desktopEnv.enable) {
    home.packages = with pkgs; [
      waybar
      startLargeScreenWaybar
    ];
  };
}
