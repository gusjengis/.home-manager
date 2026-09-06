{ pkgs, ... }:
let
  rebuildCmd = pkgs.writeShellApplication {
    name = "rebuild";
    text = ''
      exec /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild switch --impure --flake /etc/nix-modules/ "$@"
    '';
  };

  rehomeCmd = pkgs.writeShellApplication {
    name = "rehome";
    text = ''
      hm_repo="$HOME/.home-manager"

      exec home-manager switch --impure --flake "$hm_repo/" "$@"
    '';
  };
in
{
  home.packages = [
    rebuildCmd
    rehomeCmd
  ];
}
