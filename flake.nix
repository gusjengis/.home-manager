{
  description = "My first flake!";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
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
      home-manager,
      plasticscm-nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
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
      alga = inputs.alga.packages.${system}.default;
    in
    {
      nixosConfigurations = {
        nixos = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            # ./system/configuration.nix
            # ./system/steam.nix
            # /home/gusjengis/.dotfiles/system/grub.nix
            # ./system/graphics/drivers.nix
            /etc/nixos/hardware-configuration.nix
            /etc/nixos/configuration.nix
          ];
        };
      };
      homeConfigurations = {
        gusjengis = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit alga;
            inherit (pkgs) plasticscm;
          };
          modules = [ ./user/home.nix ];
        };
      };
    };
}
