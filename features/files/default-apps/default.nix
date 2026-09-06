{ config, ... }:
let
  configRoot = "${config.home.homeDirectory}/.home-manager/features/files/default-apps";
in
{
  xdg.configFile = {
    "mimeapps.list".source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/mimeapps.list";
    "xfce4/helpers.rc".source = config.lib.file.mkOutOfStoreSymlink "${configRoot}/helpers.rc";
  };
}
