{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./remote_streaming.nix
    ./windows_vm.nix
  ];
}
