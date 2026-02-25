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
      opencode
    ]
    ++ lib.optionals config.dev.enable [
      cloc
      rustup
      stable.nodejs_24
      nil
    ]
    ++ lib.optionals (config.dev.enable && config.desktopEnv.enable) [
      mesa-demos
      vulkan-tools
      mermaid-cli
      stable.typst
      posting
      oxker
      perf
      hotspot
      android-tools
      zulu17
    ]
    ++ lib.optionals (PC && config.dev.enable && config.desktopEnv.enable) [
      arduino
      android-studio
    ];
}
