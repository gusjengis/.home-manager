{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.desktopEnv.enable {
    home.packages = with pkgs; [
      gimp
      krita
      swappy
    ];
  };
}
