{
  config,
  pkgs,
  lib,
  Mac,
  PC,
  ...
}:

let
  configDir = "${config.home.homeDirectory}/.home-manager/features/desktop/hyprland/config";

  # hyprland.lua requires "platform-variables" directly, so that module name has
  # to resolve on every host. The directory is linked whole, so this per-host
  # choice is a symlink inside the repository rather than a separate link under
  # ~/.config/hypr. It is gitignored, like monitors.lua.
  platformVariables =
    if Mac then
      "variables.mac.lua"
    else if PC then
      "variables.pc.lua"
    else
      null;
in
{
  config = lib.mkIf config.desktopEnv.enable {
    home.packages =
      with pkgs;
      [
        hypridle
        hyprpaper
        libnotify
        linux-wallpaperengine
        awww
        font-awesome
        nerd-fonts.iosevka
        nerd-fonts.symbols-only
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ]
      ++ lib.optionals PC [ vial ];

    # The whole directory is linked back into this repository, so new Hypr
    # config files need no Nix change and host-local files (monitors.lua) never
    # reach the store.
    xdg.configFile."hypr".source = config.lib.file.mkOutOfStoreSymlink configDir;

    home.activation.hyprlandPlatformVariables =
      lib.mkIf (platformVariables != null)
        (lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          ln -sfn "${platformVariables}" "${configDir}/platform-variables.lua"
        '');
  };
}
