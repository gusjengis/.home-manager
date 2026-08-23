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
    ./windows_vm.nix
    ./game_dev.nix
    ./bambu.nix
  ];
}
