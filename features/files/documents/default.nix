{
  config,
  pkgs,
  ...
}:
let
  configRoot = "${config.home.homeDirectory}/.home-manager/features/files/documents";
in
{
  home.packages = with pkgs; [
    kdePackages.filelight
    libreoffice
    qimgv
    zathura
  ];

  xdg.configFile."zathura/zathurarc".source =
    config.lib.file.mkOutOfStoreSymlink "${configRoot}/zathurarc";
}
