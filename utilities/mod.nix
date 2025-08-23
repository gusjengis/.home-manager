{ config, pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
    ./git.nix
    ./screenshots.nix
    ./audio.nix
    ./disk.nix
    ./lg_tv.nix
    ./tmux.nix
  ];
  home.packages = with pkgs; [
    acpi
  ];
}
