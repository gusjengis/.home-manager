{ config, pkgs, ... }:

{
  imports = [
    ./circuits.nix
    # ./imagequeue.nix
    ./misc.nix
    ./mosaic.nix
    ./plinth.nix
  ];
}
