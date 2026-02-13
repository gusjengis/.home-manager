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
      oxker
      openssl
      rustup
      cloc
      stable.nodejs_24
      stable.typst
      mesa-demos
      vulkan-tools
      mermaid-cli
      opencode
      perf
    ]
    ++ lib.optionals config.desktopEnv.enable [
      zathura
      hotspot
      android-tools
    ]
    ++ lib.optionals (PC && config.desktopEnv.enable) [
      arduino
      android-studio
    ];
}
