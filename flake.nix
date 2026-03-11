{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    opencode.url = "github:sst/opencode?ref=v1.2.20";
    hyprlog-nixpkgs.url = "github:gusjengis/nixpkgs?ref=add-hyprlog";
    stable-nixpkgs.url = "nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    alga.url = "github:Tenzer/alga";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    handy.url = "github:cjpais/Handy?ref=v0.7.8";
    ambxst = {
      url = "github:gusjengis/Ambxst?ref=fix-special-workspaces";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      stable-nixpkgs,
      home-manager,
      nix-flatpak,
      hyprlog-nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";

      exposeInputsOverlay = (final: prev: { inputs = inputs; });

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          exposeInputsOverlay
        ];
        config.allowUnfree = true;
      };
      stable = import stable-nixpkgs {
        inherit system;
      };
      hyprlog-nixpkgs = import inputs.hyprlog-nixpkgs {
        inherit system;
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
            inherit hyprlog-nixpkgs;
          };
          modules = [
            inputs.nix-flatpak.homeManagerModules.nix-flatpak
            ./home.nix
          ];
        };
      };
    };
}
