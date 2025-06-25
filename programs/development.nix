{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    postman
    docker
    blender
    vscode
    openssl
  ];
}
