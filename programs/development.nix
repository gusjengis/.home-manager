{
  config,
  pkgs,
  inputs,
  stable,
  PC,
  lib,
  ...
}:

let
  handyPackage =
    let
      baseHandy = inputs.handy.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    baseHandy.overrideAttrs (
      old:
      let
        bunDeps = pkgs.stdenv.mkDerivation {
          pname = "handy-bun-deps";
          inherit (old) version src;

          nativeBuildInputs = [
            pkgs.bun
            pkgs.cacert
          ];

          dontFixup = true;

          buildPhase = ''
            export HOME=$TMPDIR
            bun install --frozen-lockfile --no-progress
          '';

          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/
          '';

          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = "sha256-+hUANv0w3qnK5d2+4JW3XMazLRDhWCbOxUXQyTGta/0=";
        };
      in
      {
        preBuild = ''
          cp -r ${bunDeps}/node_modules node_modules
          chmod -R +w node_modules
          substituteInPlace node_modules/.bin/{tsc,vite} \
            --replace-fail "/usr/bin/env node" "${lib.getExe pkgs.bun}"
          export HOME=$TMPDIR
          bun run build
        '';
      }
    );
in
{
  home.packages =
    with pkgs;
    [
      openssl
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    ]
    ++ lib.optionals config.desktopEnv.enable [
      handyPackage
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
