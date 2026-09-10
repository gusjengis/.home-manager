# System configuration migration

This directory holds NixOS configuration in the same repository as Home
Manager. Existing `/etc/nix-modules` and `/etc/nixos` checkouts remain untouched
as rollback copies, but `rebuild` and automatic updates use this unified flake.

`flake.nix` exposes `nixosConfigurations.<host>` for every roster entry whose
`systemManaged` value is not false.

System evaluation currently needs `--impure` because `modules/users.nix` reads
the existing public SSH key from the private secrets checkout. This preserves
remote access and produces the same top-level derivations as the legacy flake:

```bash
nix eval --impure --raw ".#nixosConfigurations.pc.config.system.build.toplevel.drvPath"
```

Every tracked host has built and switched its named output. Rollback remains:

```bash
sudo nixos-rebuild switch --impure --flake /etc/nix-modules
home-manager generations
/nix/store/<previous-home-manager-generation>/activate
```
