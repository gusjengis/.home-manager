{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.desktopEnv.enable = lib.mkDefault true;
  config = lib.mkIf config.desktopEnv.enable {
    imports = [
      ./gaming.nix
      ./game_dev.nix
    ];
  };
}
