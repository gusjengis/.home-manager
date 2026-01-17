{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    hyprlog-nixpkgs.url = "github:gusjengis/nixpkgs?ref=add-hyprlog";
    stable-nixpkgs.url = "nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      stable-nixpkgs,
      home-manager,
      hyprlog-nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = builtins.currentSystem;


      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      stable = import stable-nixpkgs {
        inherit system;
      };
      hyprlog-nixpkgs = import inputs.hyprlog-nixpkgs {
        inherit system;
      };

    in
    {
      homeConfigurations = {
        dragonflylane = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit stable;
            inherit hyprlog-nixpkgs;
          };
          modules = [
            ./home.nix
            /etc/nix-modules/homeManagerModules
          ];
        };
      };
    };
}
