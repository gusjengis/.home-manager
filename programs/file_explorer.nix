{
  config,
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
    ];
    text = builtins.readFile ../scripts/tailnet-thunar-bookmarks.sh;
  };
in
{
  home.packages = with pkgs; [
    thunar
    tumbler
    thunar-volman
    thunar-archive-plugin
    file-roller
    gvfs
    udiskie
    kdePackages.filelight
    qimgv
    zathura
    tailnetThunarBookmarks
  ];

  # ensure the shared data drive is bookmarked in thunar
  home.activation.dataThunarBookmark = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    bookmarks="${config.xdg.configHome}/gtk-3.0/bookmarks"
    mkdir -p "$(dirname "$bookmarks")"
    touch "$bookmarks"
    if ! ${pkgs.gnugrep}/bin/grep -qxF 'file:///data Data' "$bookmarks"; then
      printf 'file:///data Data\n' >> "$bookmarks"
    fi
  '';

  home.activation.tailnetThunarBookmarks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${tailnetThunarBookmarks}/bin/tailnet-thunar-bookmarks refresh || true
  '';

  systemd.user.services.tailnet-thunar-bookmarks = {
    Unit = {
      Description = "Keep Thunar Tailnet SFTP bookmarks current";
      After = [ "default.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${tailnetThunarBookmarks}/bin/tailnet-thunar-bookmarks watch";
      Restart = "always";
      RestartSec = 5;
      Environment = [
        "TAILNET_THUNAR_PROBE_TIMEOUT=10"
        "TAILNET_THUNAR_REFRESH_INTERVAL=5"
        "TAILNET_THUNAR_FULL_REFRESH_INTERVAL=60"
      ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
