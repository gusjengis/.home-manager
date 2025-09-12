{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    stable-nixpkgs.url = "nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
      stable-nixpkgs,
      home-manager,
      plasticscm-nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = builtins.currentSystem;

      exposeInputsOverlay = (final: prev: { inputs = inputs; });

      plasticscmOverlay = import ./overlays/plasticscm.nix;

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          exposeInputsOverlay
          plasticscmOverlay
        ];
      };

      stable = import stable-nixpkgs {
        inherit system;
      };

      alga = inputs.alga.packages.${system}.default;
      Mac = pkgs.hostPlatform.isAarch64;
      PC = pkgs.hostPlatform.isx86_64;
    in
    {
      homeConfigurations = {
        gusjengis = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit alga;
            inherit Mac;
            inherit PC;
            inherit inputs;
            inherit stable;
            inherit (pkgs) plasticscm;
          };
          modules = [
            ./home.nix
            /etc/nix-modules/homeManagerModules
          ];
        };
      };

    };
}
