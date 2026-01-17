{ config, pkgs, ... }:

{
  imports = [
    ./audio.nix
    ./browser.nix
    ./development.nix
    ./file_explorer.nix
    ./image_editing.nix
    ./messaging.nix
    ./notes.nix
    ./terminal.nix
  ];
}
