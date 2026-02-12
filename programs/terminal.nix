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
      	exec start-hyprland
            fi
    '';
    bashrcExtra = ''
      export PATH="$HOME/.cargo/bin:$PATH"
      TS_NAME=""
      if command -v tailscale >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        TS_NAME="$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName')"
        if [ -n "$TS_NAME" ] && [ "$TS_NAME" != "null" ]; then
          TS_NAME="$(printf '%s' "$TS_NAME" | cut -d. -f1)"
        else
          TS_NAME=""
        fi
      fi

      if [ -n "$TS_NAME" ]; then
        export PS1=" \033[1;36m\]\u\[\033[0m\]@\033[1;33m\]''${TS_NAME}\[\033[0m\] \033[1;32m\]\w\[\033[0m "
      else
        export PS1=" \033[1;36m\]\u\[\033[0m\] \033[1;32m\]\w\[\033[0m "
      fi
    '';
    profileExtra = ''
      export PATH="$HOME/.cargo/bin:$PATH"
      TS_NAME=""
      if command -v tailscale >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        TS_NAME="$(tailscale status --json 2>/dev/null | jq -r '.Self.DNSName')"
        if [ -n "$TS_NAME" ] && [ "$TS_NAME" != "null" ]; then
          TS_NAME="$(printf '%s' "$TS_NAME" | cut -d. -f1)"
        else
          TS_NAME=""
        fi
      fi

      if [ -n "$TS_NAME" ]; then
        export PS1=" \033[1;36m\]\u\[\033[0m\]@\033[1;33m\]''${TS_NAME}\[\033[0m\] \033[1;32m\]\w\[\033[0m "
      else
        export PS1=" \033[1;36m\]\u\[\033[0m\] \033[1;32m\]\w\[\033[0m "
      fi
    '';
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --impure --flake /etc/nix-modules/nixosModules/flake.nix";
      rehome = "home-manager switch --impure --flake ~/.home-manager/";
      pipes = "pipes-rs";
      venv = ". .venv/bin/activate";
      vim = "nvim";
      clean = "nix-collect-garbage -d && sudo nix-collect-garbage -d && nix store optimise && sudo nix store optimise";
      nd = "nix develop --impure";
      ta = "tmux attach || tmux";
      oc = "opencode";
      sync = "sudo ~/.home-manager/scripts/sync-repos.sh";
      update = "sudo ~/.home-manager/scripts/update.sh";
      remote = "waypipe --no-gpu --xwls ssh";
    };
  };

  systemd.user.sessionVariables.PATH = "$HOME/.cargo/bin:$PATH";

  home.packages = with pkgs; [
    pipes-rs
    tmux
    fd
    skim
    jq
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
