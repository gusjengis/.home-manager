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
      opencode
      inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
    ]
    ++ lib.optionals config.desktopEnv.enable [
      handy
      wtype
      xdotool
      gource
    ]
    ++ lib.optionals (PC && config.desktopEnv.enable) [
      lmstudio
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
