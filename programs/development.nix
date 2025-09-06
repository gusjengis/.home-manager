{
  config,
  pkgs,
  stable,
  PC,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      posting
      docker
      oxker
      openssl
      rustup
      cloc
      stable.nodejs_24
      typst
      zathura
      mesa-demos
      vulkan-tools
      mermaid-cli
      zed-editor
      sherlock-launcher
    ]
    ++ lib.optionals PC [
      cudaPackages.nsight_systems
      blender
      vscode
      immersed
      mutter
      arduino
      android-studio
    ];
}
