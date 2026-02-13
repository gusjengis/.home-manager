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
      openssl
      rustup
      stable.nodejs_24
      cloc
      opencode
      zathura
    ]
    ++ lib.optionals config.desktopEnv.enable [
      mesa-demos
      vulkan-tools
      mermaid-cli
      stable.typst
      posting
      oxker
      perf
      hotspot
      android-tools
    ]
    ++ lib.optionals (PC && config.desktopEnv.enable) [
      arduino
      android-studio
    ];
}
