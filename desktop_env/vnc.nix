{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.desktopEnv.enable {
    services.wayvnc = {
      enable = true;
      autoStart = false;
      settings = {
        address = "0.0.0.0";
        port = 5900;
        enable_auth = false;
      };
    };

    home.packages = with pkgs; [
      remmina
      tigervnc
    ];
  };
}
