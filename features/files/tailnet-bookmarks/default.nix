{
  pkgs,
  lib,
  ...
}:
let
  tailnetThunarBookmarks = pkgs.writeShellApplication {
    name = "tailnet-thunar-bookmarks";
    runtimeInputs = with pkgs; [
      coreutils
      diffutils
      glib
      gnugrep
      jq
      netcat-openbsd
      tailscale
      util-linux
    ];
    text = builtins.readFile ./tailnet-thunar-bookmarks.sh;
  };
in
{
  home.packages = [ tailnetThunarBookmarks ];

  systemd.user.services.tailnet-thunar-bookmarks = {
    Unit = {
      Description = "Keep Thunar Tailnet bookmarks current";
      After = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe tailnetThunarBookmarks} watch";
      Restart = "always";
      RestartSec = 5;
      Environment = [
        "TAILNET_THUNAR_PROBE_TIMEOUT=3"
        "TAILNET_THUNAR_REFRESH_INTERVAL=5"
        "TAILNET_THUNAR_FULL_REFRESH_INTERVAL=60"
        "TAILNET_THUNAR_OFFICE_GATEWAY=mac.tail29bd65.ts.net"
        "TAILNET_THUNAR_OG_HOST=pc.tail29bd65.ts.net"
        "TAILNET_THUNAR_OG_ADDRESS=192.168.122.18"
        "TAILNET_THUNAR_OG_SHARE=WindowsRoot"
        "TAILNET_THUNAR_OG_USER=antho"
      ];
    };

    Install.WantedBy = [ "default.target" ];
  };
}
