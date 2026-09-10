# Low-battery warnings.
#
# This used to be `scripts/battery-monitor.sh`, a `while true; sleep 60` loop
# started from autostart.lua on every host, including the desktops that have no
# battery at all. It is now a systemd timer that only exists on laptops, so it
# survives a Hyprland restart, logs to the journal, and can be inspected with
# `systemctl --user status battery-notify.timer`.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  batteryNotify = pkgs.writeShellApplication {
    name = "battery-notify";
    runtimeInputs = [ pkgs.libnotify ];
    text = builtins.readFile ./battery-notify.sh;
  };
in
{
  # Headless laptops have no notification daemon. This matches the old
  # behavior: the check was launched by Hyprland and therefore only ran in a
  # desktop session.
  config = lib.mkIf (config.laptop.enable && config.desktopEnv.enable) {
    home.packages = [ batteryNotify ];

    systemd.user.services.battery-notify = {
      Unit.Description = "Warn when the battery is low";
      Service = {
        Type = "oneshot";
        ExecStart = lib.getExe batteryNotify;
      };
    };

    systemd.user.timers.battery-notify = {
      Unit.Description = "Check the battery level every minute";
      Timer = {
        OnStartupSec = "1m";
        OnUnitActiveSec = "1m";
        AccuracySec = "10s";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
