{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

{
  options = {
    nvidia.enable = lib.mkEnableOption "enables nvidia";
  };

  config = lib.mkIf config.nvidia.enable {

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware = {
      nvidia = {
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
        open = false;
      };

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
  };
}
