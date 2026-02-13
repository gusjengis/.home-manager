{
  config,
  pkgs,
  PC,
  lib,
  ...
}:

{

  config = lib.mkIf config.desktopEnv.enable {
    home.packages =
      with pkgs;
      [
        pavucontrol
        playerctl
      ]
      ++ lib.optionals PC [ easyeffects ];
  };
}
