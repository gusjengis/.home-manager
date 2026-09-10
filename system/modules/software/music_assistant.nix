{
  config,
  lib,
  pkgs,
  ...
}:

let
  resolvConf = pkgs.writeText "music-assistant-resolv.conf" "nameserver 1.1.1.1\nnameserver 8.8.8.8\noptions edns0\n";
  # Pin an image whose baked dependencies match the overlaid Music Assistant
  # fork. In particular, this digest contains music-assistant-models 1.1.136
  # and aiohttp 3.14.1, which the fork currently requires.
  musicAssistantImage = "ghcr.io/music-assistant/server@sha256:c3ae4f8d0a9a6adaa5fabf000e31d0e558c71a6c7321117be3af98e68f4c6e43";

  musicAssistantFork = pkgs.fetchFromGitHub {
    owner = "gusjengis";
    repo = "mass-server";
    rev = "05e796764c526a6a86d1ed4bdf7c48d8862ebe22";
    hash = "sha256-ilmcIzaBne/29U1WzmZ7vGv9wdJ2MflYI1RCHyvxw6I=";
  };
in
{
  options = {
    musicAssistant.enable = lib.mkEnableOption "enables Music Assistant";
  };

  config = lib.mkIf config.musicAssistant.enable {
    virtualisation.docker.enable = true;

    systemd.services.musicassistant = {
      description = "Music Assistant";
      after = [
        "docker.service"
        "network-online.target"
      ]
      ++ lib.optionals config.tailscale.enable [ "tailscaled.service" ];
      wants = [
        "docker.service"
        "network-online.target"
      ]
      ++ lib.optionals config.tailscale.enable [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 10;
        ExecStartPre = "-${lib.getExe pkgs.docker} rm -f musicassistant";
        ExecStart = "${lib.getExe pkgs.docker} run --name=musicassistant --rm --pull=missing --network=host --privileged -v music-assistant:/data -v ${resolvConf}:/etc/resolv.conf:ro -v ${musicAssistantFork}/music_assistant:/app/venv/lib/python3.14/site-packages/music_assistant:ro -e TZ=America/Los_Angeles ${musicAssistantImage}";
        ExecStop = "${lib.getExe pkgs.docker} stop musicassistant";
        ExecStopPost = "-${lib.getExe pkgs.docker} rm -f musicassistant";
      };
    };

    networking.firewall.allowedTCPPorts = [
      8095 # web UI
    ];

    networking.firewall.allowedUDPPorts = [
      5353 # mDNS / Zeroconf
      1900 # SSDP / UPnP
    ];
  };
}
