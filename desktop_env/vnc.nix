{
  config,
  lib,
  pkgs,
  ...
}:

let
  vncviewerRemote = pkgs.writeShellScriptBin "vncviewer-remote" ''
    set -euo pipefail

    if [ "$#" -eq 0 ]; then
      printf 'Usage: vncviewer-remote host[:display] | host::port\n' >&2
      exit 64
    fi

    exec ${pkgs.tigervnc}/bin/vncviewer \
      -FullScreen \
      -FullscreenSystemKeys \
      -AlwaysCursor \
      -RemoteResize=0 \
      -Shared \
      "$@"
  '';
in
{
  config = lib.mkIf config.desktopEnv.enable {
    services.wayvnc = {
      enable = true;
      autoStart = false;
      settings = {
        address = "0.0.0.0";
        port = 5900;
        enable_auth = false;
        xkb_layout = "us";
      };
    };

    # systemd.user.services.wayvnc.Service.ExecStart = lib.mkForce "${config.home.homeDirectory}/.home-manager/scripts/start-wayvnc.sh";

    home.packages = with pkgs; [
      remmina
      tigervnc
      vncviewerRemote
    ];
  };
}
