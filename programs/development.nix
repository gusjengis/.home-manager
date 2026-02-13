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
      cloc
      stable.nodejs_24
      mesa-demos
      vulkan-tools
      opencode
      zathura
    ]
    ++ lib.optionals config.desktopEnv.enable [
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
