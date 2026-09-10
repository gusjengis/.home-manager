{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.virtual-machines = {
    enable = lib.mkEnableOption "enables virtual-machines";
    vfioPciIds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "PCI vendor and device IDs reserved for VFIO passthrough";
    };
  };

  config = lib.mkIf config.virtual-machines.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };
    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      qemu_kvm
      virt-manager
      virt-viewer
      libvirt
      OVMF
      spice-gtk
    ];

    users.users.gusjengis.extraGroups = [
      "libvirtd"
      "kvm"
    ];

    boot.kernelParams = lib.mkIf (config.virtual-machines.vfioPciIds != [ ]) [
      "intel_iommu=on"
      "iommu=pt"
      "vfio-pci.ids=${lib.concatStringsSep "," config.virtual-machines.vfioPciIds}"
    ];
    boot.initrd.kernelModules = lib.mkIf (config.virtual-machines.vfioPciIds != [ ]) [
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
    ];
  };
}
