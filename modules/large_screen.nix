{
  config,
  pkgs,
  lib,
  ...
}:

let
  startLargeScreenWaybar = pkgs.writeShellScriptBin "start-large-screen-waybar" ''
    #!/usr/bin/env bash
    set -euo pipefail

    runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    hypr_dir="$runtime_dir/hypr"

    if [ -d "$hypr_dir" ]; then
      latest_sig="$(ls -1t "$hypr_dir" | head -n 1)"
      if [ -n "$latest_sig" ]; then
        export XDG_RUNTIME_DIR="$runtime_dir"
        export HYPRLAND_INSTANCE_SIGNATURE="$latest_sig"
      fi
    fi

    exec waybar
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
