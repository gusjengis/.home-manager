{
  config,
  pkgs,
  stable,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      stable.nodejs_24
      zathura
      # Minecraft!!!
      zulu8
      prismlauncher
    ];
}
