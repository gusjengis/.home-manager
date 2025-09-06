{ config, pkgs, ... }:

{
  imports = [
    ./3d_printing.nix
    ./audio.nix
    ./browser.nix
    ./development.nix
    ./file_explorer.nix
    ./game_dev.nix
    ./image_editing.nix
    ./messaging.nix
    ./notes.nix
    ./recording.nix
    ./terminal.nix
  ];
}
