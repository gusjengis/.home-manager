{ config, pkgs, ... }:

{
  imports = [
    ./misc.nix
    ./mosaic.nix
    ./plinth.nix
    ./portfolio.nix
  ];
}
