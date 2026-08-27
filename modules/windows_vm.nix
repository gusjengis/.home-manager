{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.windowsVm;
  windowsRdp = pkgs.writeShellApplication {
    name = "windows-rdp";
    runtimeInputs = [
      pkgs.freerdp
      pkgs.libnotify
    ];
    text = ''
      set -eu

      fail() {
        notify-send "Windows RDP" "$1"
        exit 1
      }

      [ -r ${lib.escapeShellArg cfg.credentialsFile} ] || fail "Credentials file is missing"

      password=
      while IFS='=' read -r key value; do
        if [ "$key" = password ]; then
          password="$value"
        fi
      done < ${lib.escapeShellArg cfg.credentialsFile}

      [ -n "$password" ] || fail "Password is missing from credentials file"

      exec 3< <(
        printf '%s\n' \
          ${lib.escapeShellArg "/v:${cfg.address}"} \
          ${lib.escapeShellArg "/u:${cfg.user}"} \
          ${lib.escapeShellArg "/d:${cfg.domain}"} \
          /cert:tofu \
          /sec:nla \
          '/auth-pkg-list:!kerberos,ntlm,!u2u' \
          /network:auto \
          /gfx \
          /dynamic-resolution \
          /clipboard \
          /sound:sys:pulse
        printf '/p:%s\n' "$password"
      )
      unset password
      exec ${lib.getExe' pkgs.freerdp "xfreerdp"} /args-from:fd:3
    '';
  };
in
{
  options.windowsVm = {
    enable = lib.mkEnableOption "RDP launcher for the Windows VM" // {
      default = true;
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "Anthony";
      description = "Windows RDP username";
    };
    domain = lib.mkOption {
      type = lib.types.str;
      default = "AZUREGREEN";
      description = "Windows RDP domain";
    };
    address = lib.mkOption {
      type = lib.types.str;
      default = "trevornomad.tail29bd65.ts.net";
      description = "Tailnet hostname of the Windows computer";
    };
    credentialsFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/secrets/trevornomad-credentials";
      description = "RDP credential file";
    };
  };

  config = lib.mkIf (cfg.enable && config.desktopEnv.enable) {
    home.packages = [
      pkgs.freerdp
      windowsRdp
    ];

    xdg.dataFile."icons/windows-logo.webp".source = ../windows-logo.webp;

    xdg.dataFile."applications/windows-vm.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Windows 11
      Comment=Connect to TrevorNomad over RDP
      Exec=${lib.getExe windowsRdp}
      Icon=${config.xdg.dataHome}/icons/windows-logo.webp
      Terminal=false
      Categories=Network;RemoteAccess;
    '';
  };
}
