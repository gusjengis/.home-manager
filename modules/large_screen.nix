{
  config,
  pkgs,
  lib,
  ...
}:

let
  startLargeScreenWaybar = pkgs.writeShellScriptBin "start-large-screen-waybar" ''
    #!/usr/bin/env bash
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
