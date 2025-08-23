{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    unstable-nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    alga.url = "github:Tenzer/alga";
    plasticscm-nixpkgs = {
      url = "github:musjj/nixpkgs/plasticscm";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      unstable-nixpkgs,
      home-manager,
      plasticscm-nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "aarch64-linux";
      plasticscmOverlay = final: prev: {
        plasticscm-client-core = prev.callPackage (
          plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-client-core/package.nix"
        ) { };

        plasticscm-client-gui = prev.callPackage (
          plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-client-gui/package.nix"
        ) { };

        plasticscm-theme = prev.callPackage (
          plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-theme/package.nix"
        ) { };

        plasticscm-client-core-unwrapped = prev.callPackage (
          plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-client-core-unwrapped/package.nix"
        ) { };

        plasticscm-client-gui-unwrapped = prev.callPackage (
          plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-client-gui-unwrapped/package.nix"
        ) { };

        plasticscm-client-complete =
          prev.callPackage (plasticscm-nixpkgs + "/pkgs/by-name/pl/plasticscm-client-complete/package.nix")
            {
              inherit (final)
                plasticscm-client-core
                plasticscm-client-gui
                ;
            };

        plasticscm = final.plasticscm-client-complete;
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ plasticscmOverlay ];
      };

      unstable = import unstable-nixpkgs {
        inherit system;
      };

      alga = inputs.alga.packages.${system}.default;
    in
    {
      homeConfigurations = {
        gusjengis = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit alga;
            inherit inputs;
            inherit (pkgs) plasticscm;
            inherit unstable;
          };
          modules = [
            ./home.nix
            /etc/nix-modules/homeManagerModules
          ];
        };
      };

    };
}
