{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    posting
    docker
    oxker
    #    blender
    # vscode
    openssl
    #    immersed
    # mutter
    #    arduino
    #    android-studio
    rustup
    cloc
    # nodejs_24
    typst
    zathura
    mesa-demos
    vulkan-tools
    mermaid-cli
    #    cudaPackages.nsight_systems
  ];
}
