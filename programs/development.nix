{
  config,
  pkgs,
  inputs,
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
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    ]
    ++ lib.optionals config.desktopEnv.enable [
      inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default
      wtype
      xdotool
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
