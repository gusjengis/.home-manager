# Architecture

How this repository is put together, at a high level. For the ongoing cleanup
notes and the list of loose ends, see `REORGANIZATION.md`. For the system half
specifically, see `system/README.md`.

## What this repository is

One Git repository that describes **eight machines completely**: the NixOS
system configuration and the Home Manager user configuration for every one of
them. A machine is expected to be reproducible from this repository plus the
private `secrets` repository, and nothing else. Anything installed by hand is
treated as a bug.

```
flake.nix          both sets of outputs, all inputs, all pins
hosts/             the machine roster, and per-machine user settings
  default.nix        name -> { system, machineId, description }
  <host>/            user-side toggles, monitor layout, host oddities
system/            the NixOS half
  hosts/<host>/      configuration.nix + hardware-configuration.nix per machine
  modules/          shared system modules (hardware, desktop_env, software)
  users/            system-level user definitions beyond the main account
features/          the Home Manager half, one directory per feature
packages/          packages built from this repository
policy/            cross-cutting policy (currently insecure-package allowances)
legacy/            not yet reorganized, currently the Ambxst shell
```

`home.nix` is the shared user configuration; it imports `features/`, the policy
files, and `hosts/<host>`. `features/default.nix` imports every feature family
(`agents`, `desktop`, `terminal`, `remote`, `ssh`, `repo-sync`, …). A feature
directory holds everything about that feature together: its Nix declaration,
its config files, its scripts, its units, its assets.

## How a machine knows which machine it is

Every one of these machines reports the hostname `nixos`, and Tailscale's local
hostname is `nixos` too, so neither can select a configuration. Identity comes
from `/etc/machine-id`, mapped back to a name in `hosts/default.nix`.

`rehome` and `rebuild` both do that lookup, and both accept an explicit name
(`rehome t480s`) which is what a fresh install needs before its new machine-id
has been recorded.

| Host   | Arch    | Role                                                    |
| ------ | ------- | ------------------------------------------------------- |
| pc     | x86_64  | Main desktop: gaming, game dev, Bambu, Windows VM host   |
| alpha  | x86_64  | Headless server: `/data`, Nextcloud, Immich, UltraBridge |
| omega  | x86_64  | Headless server                                          |
| legion | x86_64  | Laptop, full desktop                                     |
| mac    | aarch64 | Apple Silicon laptop on Asahi, full desktop              |
| t480s  | x86_64  | ThinkPad, full desktop                                   |
| t470   | x86_64  | ThinkPad, headless                                       |
| zombie | x86_64  | Headless laptop                                          |

Roles are expressed as feature switches rather than as separate trees:
`desktopEnv.enable`, `dev.enable`, `laptop.enable`, `gaming.enable`,
`gameDev.enable`, `bambu.enable`, `windowsVm.enable`. Headless machines keep
the GTK/Qt theming on purpose, because they run GUI programs displayed
elsewhere over Waypipe.

## Flake outputs

```
homeConfigurations.<host>    all eight machines
nixosConfigurations.<host>   every host whose `systemManaged` is not false
```

Two package sets are pinned separately and deliberately:

- `nixpkgs` drives Home Manager.
- `nixpkgs-system` drives NixOS, still on the revision the fleet was running
  when the two repositories were merged.

Keeping them apart means a structural change never smuggles in a system-wide
package upgrade. Converging them is a separate, testable change.

`apple-silicon` supplies mac's Asahi support. `hyprland` tracks a personal
fork (see below). Other inputs are ordinary upstreams.

System evaluation currently needs `--impure`, because `system/modules/users.nix`
reads the fleet's public SSH key from `~/.config/secrets` at evaluation time. A
pure evaluation silently produces a system with no authorized keys, which would
lock the headless machines out, so `rebuild` always passes `--impure`.

## Everyday commands

| Command      | What it does                                                       |
| ------------ | ------------------------------------------------------------------ |
| `rehome`     | `home-manager switch` for this machine's host                        |
| `rebuild`    | `sudo nixos-rebuild switch --impure` for this machine's host         |
| `sync-repos` | Clone/pull every repository in `features/repo-sync/repos/*.list`     |
| `update-home`| Sync, then rebuild the system, then rehome, if the revision changed  |

`sync` and `update` are aliases for the last two. Which repository lists are
used depends on the machine: `core` always, `dev` when `dev.enable`, `desktop`
when `desktopEnv.enable`, plus an untracked `local.list`.

## Automatic updates

`home-update-on-first-network.service` (a user unit) runs once per boot, after
the network is up and, on desktops, after Hyprland is reachable. It runs
`update-home`, which:

1. Takes a non-blocking lock at `~/.local/state/home-manager/update.lock`.
2. Syncs the repositories.
3. Compares `HEAD` against `deployed-revision` in the same directory.
4. If they differ: `rebuild` first, and only if that succeeds, `rehome`.
5. Records the revision only after both succeed.

Two failure modes drove that design and are worth preserving:

- **The marker, not "did HEAD move".** Comparing before/after `HEAD` made a
  failed rebuild non-retryable: the next run saw an unchanged `HEAD`, skipped
  activation, and reported success. The marker means a failed deploy is retried
  until it works.
- **The lock.** Activation is what starts this service, so without the lock the
  service rebuilt the system and re-activated Home Manager from inside the
  activation that launched it. That deadlocks against the user systemd manager.
  A Home Manager activation now holds the lock for its whole run (see
  `features/repo-sync/default.nix`), and the service skips while it is held.

## How configuration reaches the machine

Editable config is deployed with `config.lib.file.mkOutOfStoreSymlink`, so
`~/.config/<thing>` points back into this checkout at
`~/.home-manager/features/<feature>/…`. Edits take effect on the program's next
start with no rebuild, programs can write their own settings back, and those
writes are already in the repository for the next `sync`.

Store-backed `source = ./file` is used only where immutability is the point.
A whole directory is linked when the application replaces files rather than
writing in place.

Consequences worth remembering:

- The checkout path is part of the contract. Moving `~/.home-manager` breaks
  every one of those links.
- Flakes ignore untracked files: `git add` a new file or the build cannot see
  it. Staging is enough, committing is not required.
- Home Manager refuses to clobber a real file or a dangling link that sits
  where a link should go. Several features carry small activation migrations
  for exactly that reason.

## Secrets

Secrets live in a separate private repository checked out at
`~/.config/secrets`, and are read **at runtime by shell code only**. Nothing
under that path is read by Nix, because anything Nix reads is copied into the
world-readable `/nix/store`.

The one deliberate exception is the fleet's *public* SSH key, which the system
module reads at evaluation time; that is what forces `--impure`. The fleet's
authorized key itself is tracked at `features/ssh/authorized_keys`.

## Hyprland

Hyprland is built from a personal fork, pinned in `flake.nix` to a branch of
`github:gusjengis/Hyprland`. Its nixpkgs deliberately does **not** follow ours,
because the fork pins the nixpkgs it is tested against.

To move the fleet: push to the branch, then

```bash
nix flake update hyprland && rehome
```

The system side no longer sets `programs.hyprland`; it keeps only the
integration pieces (XWayland, portals, polkit, PAM for swaylock).

Two hardware notes that cost real debugging time:

- On pc's NVIDIA card the DRM planes advertise `XB30`/`AB30` but not
  `XR30`/`AR30`. Hyprland tries `XR30` first, logs a failed GBM allocation, and
  falls back to `XB30`. That logged failure is expected and is not a crash.
- A crash at startup that names `deferStateCommit` means the fork lost
  `m_commitCoordinator = makeUnique<COutputCommitCoordinator>(this)` from the
  `CMonitor` constructor during a rebase. Every monitor commit then dereferences
  null. Restoring that line is the fix.

## Rollback

The pre-merge repositories are still present and untouched on each machine:
`/etc/nix-modules` (shared system modules) and `/etc/nixos` (that machine's
system configuration). If a unified system generation misbehaves:

```bash
sudo nixos-rebuild switch --impure --flake /etc/nix-modules
home-manager generations                     # pick the previous one
/nix/store/<previous-generation>/activate
```

Both are also reachable from the boot menu and from
`home-manager generations`. They are kept only as a rollback path and should be
retired once the unified layout has run for a while.

## Adding things

**A machine.** Add it to `hosts/default.nix` with its arch and machine-id, add
`hosts/<name>/default.nix` with its feature switches, add
`system/hosts/<name>/` with that machine's `configuration.nix` and
`hardware-configuration.nix`, `git add` all of it, then `rehome <name>` and
`rebuild <name>` on the machine itself.

**A feature.** Create `features/<family>/<name>/default.nix`, import it from
the family's `default.nix`, and keep its config files, scripts and units in the
same directory. Gate it on `desktopEnv.enable`, `dev.enable` or `laptop.enable`
if it does not belong everywhere.

**A system module.** Put it in `system/modules/<area>/`, import it from
`system/modules/default.nix`, and give it an `enable` option with a default
that preserves current behaviour on every machine.
