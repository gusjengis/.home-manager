{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  options.repo.networkmanager.enable = lib.mkEnableOption "shared NetworkManager defaults" // {
    default = true;
  };

  imports = [
    ./hardware/asahi.nix
    ./hardware/gpu_drivers.nix
    ./hardware/grub.nix
    ./desktop_env/hyprland.nix
    ./desktop_env/gnome.nix
    ./desktop_env/login.nix
    ./desktop_env/bedtime_lockout.nix
    ./software/nvim.nix
    ./software/git.nix
    ./software/vial.nix
    ./software/tailscale.nix
    ./software/office_network_drives.nix
    ./software/vms.nix
    ./software/home_assistant.nix
    ./software/zone_configurator.nix
    ./software/ble_scale_sync.nix
    ./software/music_assistant.nix
    ./software/parakeet_asr.nix
    ./software/data_drive.nix
    ./software/nextcloud.nix
    ./software/immich.nix
    ./software/ultrabridge.nix
    (./software + "/josh's_mass.nix")
    ./users.nix
  ];

  config = {
    grub.enable = lib.mkDefault true;
    nvidia.enable = lib.mkDefault false;
    login.gnome.enable = lib.mkDefault false;
    gnome.enable = lib.mkDefault false;
    hyprland.enable = lib.mkDefault true;
    bedtimeLockout.enable = lib.mkDefault (config.hyprland.enable || config.gnome.enable);
    nvim.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    vial.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
    homeAssistant.enable = lib.mkDefault false;
    zoneConfigurator.enable = lib.mkDefault config.homeAssistant.enable;
    bleScaleSync.enable = lib.mkDefault false;
    musicAssistant.enable = lib.mkDefault false;
    parakeetAsr.enable = lib.mkDefault false;
    dataDrive.server.enable = lib.mkDefault false;
    dataDrive.client.enable = lib.mkDefault (!config.dataDrive.server.enable);
    nextcloud.enable = lib.mkDefault false;
    immich.enable = lib.mkDefault false;
    immich.funnel.enable = lib.mkDefault false;
    ultrabridge.enable = lib.mkDefault false;
    ultrabridge.funnel.enable = lib.mkDefault false;
    joshsMass.enable = lib.mkDefault false;
    virtual-machines.enable = lib.mkDefault false;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.warn-dirty = false;

    services.getty.autologinUser = "gusjengis";
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    zramSwap.enable = true;
    time.timeZone = "America/Los_Angeles";
    networking.networkmanager.enable = config.repo.networkmanager.enable;
    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
        {
          from = 47984;
          to = 47990;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
        {
          from = 47998;
          to = 48010;
        }
      ];
      allowedTCPPorts = [
        48010
      ];
    };
    nixpkgs.config.allowBroken = true;
    # Turn of password for sudo, so annoying
    security.sudo.extraConfig = ''
      %wheel ALL=(ALL) NOPASSWD: ALL
    '';
    hardware.bluetooth.enable = true; # enables support for Bluetooth
    hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
    nixpkgs.config.allowUnfree = true;
    systemd.services."NetworkManager-wait-online".enable = false;
    programs.nix-ld.enable = true;
    programs.dconf.enable = true;
    virtualisation.docker.enable = true;
    systemd.services.docker.after = [
      "network-online.target"
    ]
    ++ lib.optionals config.tailscale.enable [ "tailscaled.service" ];
    systemd.services.docker.wants = [
      "network-online.target"
    ]
    ++ lib.optionals config.tailscale.enable [ "tailscaled.service" ];
    systemd.services."podman-homeassistant" = lib.mkIf config.tailscale.enable {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
    };
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    services.gnome.core-apps.enable = false;

    services.logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    environment.systemPackages = with pkgs; [
      ntfs3g
    ];

    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var allowed = [
          "org.freedesktop.udisks2.filesystem-mount",
          "org.freedesktop.udisks2.filesystem-mount-system",
          "org.freedesktop.udisks2.filesystem-unmount-others",
          "org.freedesktop.udisks2.encrypted-unlock",
          "org.freedesktop.udisks2.encrypted-unlock-system"
        ];
        if (
          allowed.indexOf(action.id) >= 0 &&
          subject.active &&
          subject.local &&
          subject.isInGroup("wheel")
        ) {
          return polkit.Result.YES;
        }
      });
    '';

    fonts.packages = with pkgs; [
      carlito
      commit-mono
      dejavu_fonts
      nerd-fonts.meslo-lg
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    fonts.fontconfig.defaultFonts = {
      serif = [
        "Noto Serif"
        "DejaVu Serif"
      ];
      sansSerif = [
        "Noto Sans"
        "DejaVu Sans"
      ];
      monospace = [
        "CommitMono Nerd Font"
        "DejaVu Sans Mono"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_12;
  };
}
