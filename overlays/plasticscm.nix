final: prev:
let
  hashes = {
    plasticscm-theme = "sha256-GSZ2j/xZOUDI2SoqLWeGYq8YdPGLJ7ZXaJaOrsru8PY=";
    plasticscm-client-core-unwrapped = "sha256-4ywIltUBg050pm7h67ZabvBOrCsOpt8KjlcHJqsLLjQ=";
    plasticscm-client-gui-unwrapped = "sha256-H+9vi9Yfz3uVA/dUwpMmrPOfGt0elAJ+jeFs2usp5L0=";
  };

  fromFork = rel: prev.callPackage (final.inputs.plasticscm-nixpkgs + rel) { };

  bumpHash =
    base:
    base.overrideAttrs (old: {
      src = old.src.overrideAttrs (_: {
        outputHash =
          hashes.${old.pname} or (throw "Missing hash for ${old.pname} in overlays/plasticscm.nix");
      });
    });
in
{
  plasticscm-theme = bumpHash (fromFork "/pkgs/by-name/pl/plasticscm-theme/package.nix");

  plasticscm-client-core-unwrapped = bumpHash (
    fromFork "/pkgs/by-name/pl/plasticscm-client-core-unwrapped/package.nix"
  );

  plasticscm-client-gui-unwrapped = bumpHash (
    fromFork "/pkgs/by-name/pl/plasticscm-client-gui-unwrapped/package.nix"
  );

  plasticscm-client-core = fromFork "/pkgs/by-name/pl/plasticscm-client-core/package.nix";

  plasticscm-client-gui = fromFork "/pkgs/by-name/pl/plasticscm-client-gui/package.nix";

  plasticscm-client-complete =
    prev.callPackage
      (final.inputs.plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-client-complete/package.nix")
      {
        inherit (final)
          plasticscm-client-core
          plasticscm-client-gui
          ;
      };

  plasticscm = final.plasticscm-client-complete;
}
