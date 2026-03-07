{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./gaming.nix
    ./game_dev.nix
    ./bambu.nix
    ./large_screen.nix
  ];
}
