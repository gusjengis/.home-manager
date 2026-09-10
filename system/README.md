# System configuration migration

This directory is the additive first stage of moving NixOS and Home Manager
into one repository. Existing `/etc/nix-modules` and `/etc/nixos` checkouts
remain untouched and are still the active rebuild path.

`flake.nix` exposes `nixosConfigurations.<host>` for every roster entry whose
`systemManaged` value is not false.

System evaluation currently needs `--impure` because `modules/users.nix` reads
the existing public SSH key from the private secrets checkout. This preserves
remote access and produces the same top-level derivations as the legacy flake:

```bash
nix eval --impure --raw ".#nixosConfigurations.pc.config.system.build.toplevel.drvPath"
```

Do not switch rebuild automation to this flake until the mac profile is tracked
and each host has built its named output. Until then, rollback is simply the
existing command:

```bash
sudo nixos-rebuild switch --impure --flake /etc/nix-modules
```
