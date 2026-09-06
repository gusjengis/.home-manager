{
  config,
  lib,
  pkgs,
  ...
}:

let
  mkRepoScript =
    name: script:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ pkgs.bash ];
      text = ''
        exec bash "$HOME/.home-manager/scripts/${script}" "$@"
      '';
    };

  sunshineConnect = mkRepoScript "sunshine-connect" "sunshine-connect.sh";
  sunshineStreamHost = mkRepoScript "sunshine-stream-host" "sunshine-stream-host.sh";
in
{
  options.remoteStreaming.enable = lib.mkEnableOption "Sunshine/Moonlight remote streaming" // {
    default = true;
  };

  config = lib.mkIf (config.remoteStreaming.enable && config.desktopEnv.enable) {
    home.packages = with pkgs; [
      curl
      jq
      libnotify
      moonlight-qt
      tailscale
      sunshineConnect
      sunshineStreamHost
    ];

    programs.bash.shellAliases = {
      pcstream = "sunshine-connect pc";
    };
  };
}
