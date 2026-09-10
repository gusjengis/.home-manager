{
  config,
  lib,
  ...
}:

# Shared network data drive.
#
# The server (alpha) exports its btrfs RAID1 mirror at /data over NFSv4,
# restricted to the tailnet. Every other machine automounts it at /data,
# so all computers see the same files at the same path.
{
  options = {
    dataDrive = {
      server.enable = lib.mkEnableOption "export /data over NFS to the tailnet";
      client.enable = lib.mkEnableOption "mount the shared data drive at /data";
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !(config.dataDrive.server.enable && config.dataDrive.client.enable);
          message = "dataDrive: server and client cannot both be enabled on the same machine.";
        }
      ];
    }

    (lib.mkIf config.dataDrive.server.enable {
      services.nfs.server = {
        enable = true;
        # NFSv4 only; v3 would need rpcbind/mountd and extra ports.
        # all_squash: this is a single-owner cloud drive, so every access
        # from every machine maps to gusjengis:users. Keeps ownership
        # uniform no matter which client or user wrote the file.
        exports = ''
          /data 100.64.0.0/10(rw,no_subtree_check,all_squash,anonuid=1000,anongid=100)
        '';
      };

      services.nfs.settings.nfsd = {
        vers3 = false;
        vers4 = true;
        "vers4.0" = false;
        "vers4.1" = true;
        "vers4.2" = true;
      };

      # Only reachable over tailscale, invisible to LAN/internet.
      networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 2049 ];
    })

    (lib.mkIf config.dataDrive.client.enable {
      boot.supportedFilesystems = [ "nfs" ];

      fileSystems."/data" = {
        device = "alpha:/data";
        fsType = "nfs";
        options = [
          "nfsvers=4.2"
          # hard: operations block until the server returns rather than
          # erroring out; no silent data corruption on flaky links.
          "hard"
          "noatime"
          "_netdev"
          "nofail"
          # Mount lazily on first access instead of at boot, and unmount
          # again after 10 minutes idle. Combined with nofail this keeps
          # boot and shutdown from hanging when alpha is unreachable.
          "noauto"
          "x-systemd.automount"
          "x-systemd.idle-timeout=600"
          "x-systemd.mount-timeout=30s"
        ];
      };
    })
  ];
}
