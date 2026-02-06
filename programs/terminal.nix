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
    initExtra = ''
            if [ -f ~/.config/secrets/api_keys/env_vars ]; then
              set -a
              source ~/.config/secrets/api_keys/env_vars
              set +a
            fi

            if [ -z "$WAYLAND_DISPLAY" ] && [ "x$XDG_VTNR" = "x1" ]; then
      	exec Hyprland
            fi
    '';
    bashrcExtra = ''
      export PATH="$HOME/.cargo/bin:$PATH"
      export PS1=" \033[1;32m\]\w\[\033[0m "
    '';
    profileExtra = ''
      export PATH="$HOME/.cargo/bin:$PATH"
      export PS1=" \033[1;32m\]\w\[\033[0m "
    '';
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --impure --flake /etc/nixos/";
      rehome = "home-manager switch --impure --flake ~/.home-manager/";
      pipes = "pipes-rs";
      venv = ". .venv/bin/activate";
      vim = "nvim";
      clean = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise && sudo nix store optimise";
      nd = "nix develop --impure";
      ta = "tmux attach || tmux";
      oc = "opencode";
      sync = "~/.home-manager/scripts/sync-repos.sh";
    };
  };

  systemd.user.sessionVariables.PATH = "$HOME/.cargo/bin:$PATH";

  home.packages = with pkgs; [
    pipes-rs
    tmux
    fd
    skim
  ];

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  news.display = "silent";
}
