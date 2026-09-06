{
  config,
  pkgs,
  lib,
  ...
}:
let
  configRoot = "${config.home.homeDirectory}/.home-manager/features/terminal/pipes-rs";
in
{
  config = lib.mkIf config.desktopEnv.enable {
    home.packages = [ pkgs.pipes-rs ];

    programs.bash.shellAliases.pipes = "pipes-rs";

    xdg.configFile."pipes-rs/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${configRoot}/config.toml";
  };
}
