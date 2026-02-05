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
      stable.typst
      zathura
      mesa-demos
      vulkan-tools
      mermaid-cli
      opencode
      perf
      hotspot
    ]
    ++ lib.optionals PC [
      dotnetCorePackages.dotnet_9.sdk
      protonup-qt
      blender
      vscode
      arduino
      android-studio
      zulu8
      prismlauncher
      atlauncher
    ];
}
