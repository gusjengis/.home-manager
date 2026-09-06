{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    hyprlog-nixpkgs.url = "github:gusjengis/nixpkgs?ref=add-hyprlog";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    alga.url = "github:Tenzer/alga";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    rmatrix.url = "github:RoastBeefer00/rmatrix";
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ambxst = {
      url = "github:gusjengis/Ambxst?ref=fix-special-workspaces";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Mail helpers keep their own verified nixpkgs inputs.
    # OAuth 2.0 token broker, feeds XOAUTH2 tokens to the mail watcher.
    ortie = {
      url = "github:pimalaya/ortie/274bd4c6e5ab50ecafd71ae52c051ffd596156af";
    };
    # IMAP IDLE watcher, fires desktop notifications without a mail client running.
    carillon = {
      url = "github:pimalaya/carillon/564d88dc2778b347040bf322130dac69f23e17ab";
    };
    # Caveman skill suite for OpenCode (output-token compression).
    # Update to latest: nix flake update caveman && rehome
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
    # OpenCode pinned upstream, ahead of the nixpkgs package.
    # Bump by editing the tag below, then: nix flake update opencode && rehome
    opencode = {
      url = "github:anomalyco/opencode/v1.18.29";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-flatpak,
      hyprlog-nixpkgs,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      system = if builtins ? currentSystem then builtins.currentSystem else "x86_64-linux";

      exposeInputsOverlay = (final: prev: { inputs = inputs; });

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          exposeInputsOverlay
        ];
        config.allowUnfree = true;
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
