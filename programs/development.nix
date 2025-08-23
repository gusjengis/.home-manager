{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    postman
    docker
    #    blender
    # vscode
    openssl
    #    immersed
    # mutter
    #    arduino
    #    android-studio
    rustup
    cloc
    nodejs_24
    # alacritty
    typst
    zathura
    #    cudaPackages.nsight_systems
  ];
}
