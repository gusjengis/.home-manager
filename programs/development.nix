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
      numlockx
      openssl
      rustup
      cloc
      stable.nodejs_24
      stable.typst
      zathura
      mesa-demos
      vulkan-tools
      mermaid-cli
      stable.zed-editor
      code-cursor
    ]
    ++ lib.optionals PC [
      # cudaPackages.nsight_systems
      protonup-qt
      blender
      vscode
      immersed
      mutter
      arduino
      android-studio
    ];
}
