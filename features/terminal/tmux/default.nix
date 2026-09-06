{ config, pkgs, ... }:
let
  configRoot = "${config.home.homeDirectory}/.home-manager/features/terminal/tmux";
in
{
  home.packages = [ pkgs.tmux ];

  programs.bash.shellAliases.ta = "tmux attach || tmux";

  xdg.configFile = {
    "tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/tmux.conf";
    "tmux/github_dark.tmux".source =
      config.lib.file.mkOutOfStoreSymlink "${configRoot}/github_dark.tmux";
    "tmux/plugins".source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/plugins";
    "tmux/open_github.sh".source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/open_github.sh";
    "tmux/tmux_jobs.sh".source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/tmux_jobs.sh";
    "tmux/tmux_session_dispensary.sh".source =
      config.lib.file.mkOutOfStoreSymlink "${configRoot}/tmux_session_dispensary.sh";
  };
}
