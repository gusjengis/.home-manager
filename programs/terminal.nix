{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];

  programs.bash = {
    enable = true;
    initExtra = "";
    bashrcExtra = ''export PATH="$HOME/.cargo/bin:$PATH"'';
    profileExtra = ''export PATH="$HOME/.cargo/bin:$PATH"'';
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --impure --flake /etc/nixos/";
      rehome = "home-manager switch --impure --flake ~/.home-manager/";
      pipes = "pipes-rs";
      venv = ". .venv/bin/activate";
      vim = "nvim";
      clean = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise && sudo nix store optimise";
      nd = "nix develop";
    };
  };

  systemd.user.sessionVariables.PATH = "$HOME/.cargo/bin:$PATH";

  home.packages = with pkgs; [
    pipes-rs
  ];

  home.file.".config/pipes-rs/config.toml".source = ~/.home-manager/config_files/pipes-rs/config.toml;
  home.file.".config/pipes-rs/config.toml".force = true;

  home.activation.symlinkKittyConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/kitty

    ln -sf $HOME/.home-manager/config_files/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
  '';

}
