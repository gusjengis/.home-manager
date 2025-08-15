{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    postman
    docker
    blender
    vscode
    openssl
    immersed
    mutter
    arduino
    android-studio
    rustup
    cloc
    alacritty
    typst
    zathura
    cudaPackages.nsight_systems
  ];
}
