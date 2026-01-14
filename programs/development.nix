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
      supercollider
      opencode
      cockatrice
    ]
    ++ lib.optionals PC [
      dotnetCorePackages.dotnet_9.sdk
      protonup-qt
      blender
      vscode
      immersed
      mutter
      arduino
      android-studio
      zulu8
      prismlauncher
      atlauncher
      lutris
    ];
}
