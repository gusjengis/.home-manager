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

  sunshineLauncher = mkRepoScript "sunshine-launcher" "sunshine-launcher.sh";
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
      openssh
      tailscale
      sunshineConnect
      sunshineLauncher
      sunshineStreamHost
    ];

    programs.bash.shellAliases = {
      moonlight-remote = "sunshine-launcher";
      pcstream = "sunshine-connect pc";
      remote-game = "sunshine-launcher";
      sunshine-remote = "sunshine-launcher";
    };
  };
}
