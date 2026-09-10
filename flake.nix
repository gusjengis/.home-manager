{
  description = "Home Manager Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
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
    # Hyprland, built from a personal fork rather than nixpkgs.
    #
    # Tracks a branch, so `nix flake update hyprland && rehome` moves every
    # machine to whatever that branch points at now. To go back to upstream,
    # change this URL to github:hyprwm/Hyprland/main for the dev channel or to
    # a tag like github:hyprwm/Hyprland/v0.57.0 for a release.
    #
    # Its nixpkgs is deliberately NOT made to follow ours. Hyprland pins the
    # nixpkgs it is tested against, and overriding that is the usual cause of
    # compile failures when nixpkgs-unstable drifts.
    hyprland = {
      url = "github:gusjengis/Hyprland/personal";
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
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      # Every machine this configuration is deployed to, with the machine-id
      # `rehome` uses to pick one automatically.
      hosts = import ./hosts;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            # Make the flake inputs reachable from any module through `pkgs`.
            (final: prev: { inputs = inputs; })
            # Packages built from this repository.
            (import ./packages)
          ];
          config.allowUnfree = true;
        };

      homeConfigurationFor =
        hostName: host:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor host.system;
          extraSpecialArgs = {
            inherit inputs hosts hostName;
          };
          modules = [
            inputs.nix-flatpak.homeManagerModules.nix-flatpak
            ./home.nix
          ];
        };
    in
    {
      homeConfigurations = lib.mapAttrs homeConfigurationFor hosts;
    };
}
