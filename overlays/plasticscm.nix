# overlays/plasticscm.nix
final: prev:
let
  # Centralize updated hashes
  hashes = {
    plasticscm-theme = "sha256-2qeYrnqgzh2uG/Met7WdpR9WVQJ9nx8+IlJL5C45kYA=";
    # Fill these after prefetching:
    # plasticscm-client-core = "sha256-...";
    # plasticscm-client-gui  = "sha256-...";
  };

  # Helper: replace src with canonical URL + pinned hash
  overridePlastic =
    base:
    base.overrideAttrs (old: {
      src = prev.fetchurl {
        url = "https://www.plasticscm.com/plasticrepo/stable/debian/amd64/${old.pname}_${old.version}_amd64.deb";
        hash = hashes.${old.pname} or (throw "Missing hash for ${old.pname} in overlays/plasticscm.nix");
      };
    });

  # Pull the package from the fork. We reference the fork via final.inputs (see flake wiring below).
  fromFork = relPath: prev.callPackage (final.inputs.plasticscm-nixpkgs + relPath) { };

in
{
  plasticscm-theme = overridePlastic (fromFork "/pkgs/by-name/pl/plasticscm-theme/package.nix");
  plasticscm-client-core = overridePlastic (
    fromFork "/pkgs/by-name/pl/plasticscm-client-core/package.nix"
  );
  plasticscm-client-gui = overridePlastic (
    fromFork "/pkgs/by-name/pl/plasticscm-client-gui/package.nix"
  );

  # If the *-unwrapped ones also fetch .debs and fail, add them here too:
  # plasticscm-client-core-unwrapped = overridePlastic (fromFork "/pkgs/by-name/pl/plasticscm-client-core-unwrapped/package.nix");
  # plasticscm-client-gui-unwrapped  = overridePlastic (fromFork "/pkgs/by-name/pl/plasticscm-client-gui-unwrapped/package.nix");

  # Keep your convenience alias if you depend on it elsewhere:
  plasticscm = final.plasticscm-client-complete;
}
