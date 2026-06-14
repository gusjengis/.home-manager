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
      inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
    ]
    ++ lib.optionals config.desktopEnv.enable [
      inputs.claude-desktop-linux-flake.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs
      handy
      wtype
      xdotool
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
