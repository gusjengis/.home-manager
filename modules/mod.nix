{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./gaming.nix
    ./remote_streaming.nix
    ./game_dev.nix
    ./bambu.nix
    ./large_screen.nix
  ];
}
