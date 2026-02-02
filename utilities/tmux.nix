{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{

  home.packages = with pkgs; [
    tmux
    fd
    skim
  ];

  home.activation.symlinkHyprlandConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/tmux
    mkdir -p ~/.config/xfce4
    mkdir -p ~/.local/share/applications

    ln -sf $HOME/.home-manager/config_files/tmux/tmux.conf $HOME/.config/tmux/tmux.conf
    ln -sf $HOME/.home-manager/config_files/xfce4/helpers.rc $HOME/.config/xfce4/helpers.rc
    ln -sf $HOME/.home-manager/config_files/mimeapps.list $HOME/.config/mimeapps.list
    ln -sf $HOME/.home-manager/config_files/local/share/applications/nvim.desktop $HOME/.local/share/applications/nvim.desktop
    ln -sf $HOME/.home-manager/config_files/opencode/model.json $HOME/.local/state/opencode/model.json
    ln -sf $HOME/.home-manager/config_files/opencode/kv.json $HOME/.local/state/opencode/kv.json
  '';
}
