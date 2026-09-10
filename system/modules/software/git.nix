{
  config,
  pkgs,
  lib,
  ...
}:

{
  options = {
    git.enable = lib.mkEnableOption "enables git";
  };

  config = lib.mkIf config.git.enable {

    environment.systemPackages = with pkgs; [
      git
      gh
      lazygit
    ];

  };
}
