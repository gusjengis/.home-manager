{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    stable-nixpkgs.url = "nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    alga.url = "github:Tenzer/alga";

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    plasticscm-nixpkgs = {
      url = "github:musjj/nixpkgs/plasticscm";
      flake = false;
    };
    old-nixpkgs.url = "nixpkgs/nixos-24.11";
  };

  outputs =
    {
      self,
      nixpkgs,
      old-nixpkgs,
      stable-nixpkgs,
      home-manager,
      plasticscm-nixpkgs,
      nix-flatpak,

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
        config.allowUnfree = true;
      };
      stable = import stable-nixpkgs {
        inherit system;
      };
      old = import old-nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      alga = inputs.alga.packages.${system}.default;
      Mac = pkgs.stdenv.hostPlatform.isAarch64;
      PC = pkgs.stdenv.hostPlatform.isx86_64;
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
            inherit old;
            inherit (pkgs) plasticscm;
          };
          modules = [
            inputs.nix-flatpak.homeManagerModules.nix-flatpak
            ./home.nix
            /etc/nix-modules/homeManagerModules
          ];
        };
      };
    };
}
