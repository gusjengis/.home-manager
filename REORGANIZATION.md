# Reorganization Handoff

Status of the restructuring of this Home Manager configuration.

## The goal

One folder per feature, one folder per machine. Opening a feature folder should
show everything about that feature: its Nix declaration, its config files, its
scripts, its assets, its services. Opening a host folder should show everything
that makes that machine different from the others.

Every machine builds from this repository alone. Nothing a machine needs is
allowed to live in an untracked file or in a hand-built directory.

## Rules being followed

- Editable config is deployed with `config.lib.file.mkOutOfStoreSymlink`, so
  `~/.config/x` points back into this repository. Edits apply on the program's
  next start with no rebuild, programs can write their own settings back, and
  changes sync to other machines through Git.
- Store-backed `source = ./file` is used only where immutability is wanted
  (currently: OpenCode's generated `AGENTS.md` and the pinned caveman skills).
- Link a whole directory when the application replaces files atomically rather
  than writing in place. OpenCode proved this: it replaced individual symlinks
  with regular files, so `~/.local/state/opencode` is now a directory link.
- Scripts that a systemd unit depends on are packaged with
  `writeShellApplication` and explicit `runtimeInputs`, so a generation cannot
  break when the checkout moves. Scripts invoked interactively can stay as
  live-linked files.
- Aliases live with the thing they invoke, not in a central alias list.
- Secrets are read at runtime by shell code only. Nothing under
  `~/.config/secrets` is ever read by Nix, because anything Nix reads is copied
  into the world-readable `/nix/store`.
- Anything installed by hand is a bug. `cargo install`, `cmake && make`, and a
  package that only exists in an untracked file are all the same failure: the
  machine stops being reproducible from this repository.

## Layout

```
flake.nix            inputs and one homeConfiguration per machine
home.nix             what every machine shares, plus the shared option defaults
hosts/               one folder per machine, and the machine-id roster
packages/            packages built from this repository, exposed as an overlay
features/            one folder per feature
legacy/ambxst/       old shell, isolated, still launchable, not integrated
policy/              insecure package allowances, with owners documented
```

```
features/
├── agents/          opencode (config, plugins, state, caveman skills), claude-code, python
├── applications/    chromium, communication, handy, mail, obsidian, onepassword
├── desktop/         cursor, hyprland, quickshell, screenshots, theme, wallpaper,
│                    webapps
├── development/     tools, game-development
├── files/           thunar, documents, default-apps, tailnet-bookmarks
├── gaming/
├── git/             git, gh, lazygit, GH_TOKEN wiring
├── hardware/        battery
├── java/            shared by gaming and development
├── media/           playback, creation
├── printing/bambu/
├── remote/          windows-vm (RDP launchers, OG on-demand start)
├── repo-sync/       packaged scripts, repo lists, boot service
├── secrets/         runtime env loading
├── ssh/             package, config, authorized_keys, key permissions
├── system-tools/    archives, connectivity, hardware, monitoring, shell, storage
└── terminal/        shell (bash/commands/tools), tmux, kitty, pipes-rs, rjmatrix
```

## Machines

| host     | arch    | role                                    | monitors.lua |
|----------|---------|-----------------------------------------|--------------|
| `pc`     | x86_64  | main desktop; gaming, gamedev, bambu, VM | yes          |
| `alpha`  | x86_64  | headless server                          | no           |
| `omega`  | x86_64  | headless server                          | no           |
| `legion` | x86_64  | laptop, full desktop                     | no           |
| `mac`    | aarch64 | Asahi laptop, full desktop               | yes          |
| `t480s`  | x86_64  | laptop, full desktop                     | yes          |
| `t470`   | x86_64  | laptop, headless                         | no           |
| `zombie` | x86_64  | laptop, headless                         | no           |

### How a machine knows which configuration it is

Every one of these machines reports the hostname `nixos`, so the hostname is
useless as an identifier. Tailscale is no better: its local `HostName` is also
`nixos` on all of them, and the distinct tailnet name only exists in `DNSName`,
which is control-plane state rather than anything the machine knows about
itself. Using it would mean a rebuild needs a running daemon and a reachable
coordination server, and that renaming a machine in a web dashboard silently
changes what it builds.

`/etc/machine-id` is used instead. It is unique per install, readable offline,
needs no daemon, and exists before networking. `hosts/default.nix` maps each id
to a name, and `rehome` bakes that table into itself at build time.

```bash
rehome            # resolve this machine from /etc/machine-id
rehome mac        # build a named host explicitly
HM_HOST=mac rehome
```

An unrecognised machine-id is an error, not a guess. It prints the id, the
known hosts, and — purely as a hint — the name Tailscale has for the machine.

A reinstall regenerates the machine-id. Use `rehome <name>` until the new id is
recorded in `hosts/default.nix`.

## Done

The whole old deployment mechanism is gone: `scripts/symlink.sh`,
`link_files.nix`, the `config_files/` tree, `modules/`, `desktop_env/`, and
finally `scripts/` itself. Every configuration file is owned by the feature
that uses it, and every machine-specific value is owned by a host folder.

Deleted along the way: Thunderbird (replaced by Mailspring), Signal, Krita,
Swappy, all Eww configs and helper scripts, Wofi and the accent pipeline, all of
Sunshine and Moonlight, the Waypipe launcher, the Eww calendar, `profile.webp`,
empty `readme.md`, the tracked `result` symlink, `hyprpaper` and its config,
`clean-broken-desktop-entries.sh`, the orphaned `current-window.sh` and
`open_chromium.sh`, and the unused `stable-nixpkgs`, `ortie`, `carillon` and
`hyprlog-nixpkgs` flake inputs.

### Hosts, and the end of the untracked files

`modules.nix` and `local.nix` were gitignored, so each machine's identity lived
only on that machine. They are replaced by `hosts/<name>/default.nix`, and
`flake.nix` now exposes one `homeConfiguration` per machine.

- `monitors.lua` is tracked as `hosts/<name>/monitors.lua` and symlinked into
  the Hypr config directory during activation, the same way
  `platform-variables.lua` already was. The `mac` dual-monitor HDR layout
  existed in no repository before this.
- `.gitignore` now lists only the two activation-written symlinks, whose targets
  are themselves tracked.
- Because each host declares its own `system`, `builtins.currentSystem` is gone
  and **`rehome` no longer passes `--impure`**.
- `Mac` and `PC` were architecture flags wearing machine-name costumes, passed
  through `specialArgs`. They are gone; modules test
  `pkgs.stdenv.hostPlatform.isx86_64` directly, which is what they always meant.

Real breakage this surfaced, now fixed:

- `hyprsunset` is started by `autostart.lua` on every desktop host but was only
  installed on `pc`, through `local.nix`. It was silently missing on `legion`,
  `mac` and `t480s`. It now belongs to the hyprland feature.
- `features/development/tools.nix` declared a module argument `stable` that
  nothing provided.
- `alga` and `easyeffects` were undeclared everywhere except `pc`; they are now
  `hosts/pc/default.nix`.

### Hyprland is built from a fork, declaratively

Hyprland used to be compiled by hand into `~/Documents/Code/Hyprland/build` on
every machine, and `bash.nix` execed that path directly. It is now a flake
input pinned to a branch:

```nix
hyprland.url = "github:gusjengis/Hyprland/personal";
```

`nix flake update hyprland && rehome` moves a machine to whatever that branch
points at now. Switching to upstream later is a URL change: `hyprwm/Hyprland/main`
for dev, or a tag for a release. Its nixpkgs deliberately does not follow ours,
because Hyprland pins the nixpkgs it is tested against.

Doing this found that the `personal` branch did not compile. Commit `7f0d9d6`
("workspace: reuse rule updates for blur") removed six listener declarations
from `CMonitor::m_listeners`. Five were the blur listeners it meant to replace
with workspace rules, but `commitResult` came from upstream and is still used in
`Monitor.cpp`. Fixed in `976e510a9`. It went unnoticed because the running
binary was built from an older commit and `build/` was never recompiled.

**Hyprland is now Home Manager's, not the system's.** `programs.hyprland` was
removed from `/etc/nix-modules/desktop_env/hyprland.nix`. It installed a second
Hyprland from nixpkgs, and its capability wrapper at `/run/wrappers/bin/Hyprland`
shadowed the fork on `PATH`, so `start-hyprland`, which resolves through
`execvp`, launched the nixpkgs build. Nothing needed the system copy: no display
manager is configured, so its session entry was never read.

What moved, and where it went:

| was provided by `programs.hyprland` | now |
|---|---|
| `hyprland` | Home Manager, from the fork |
| `xdg-desktop-portal-hyprland` | Home Manager, from the same flake input |
| `xwayland` | `programs.xwayland.enable` on the system |
| `cap_sys_nice` wrapper | gone; the hand-built binary never used it either |

The portal must match the compositor's commit or screen sharing and the file
picker break, which is why it comes from the same input. The GTK backend stays
system-wide for Flatpak, with `xdg.portal.config.common.default = [ "gtk" ]`.
`/etc/nix-modules/desktop_env/bedtime_lockout.nix` no longer refers to
`${pkgs.hyprland}/bin/hyprctl`; it resolves `hyprctl` from the user's profile,
so it neither builds a second Hyprland nor risks a mismatched IPC.

### Battery warnings

`scripts/battery-monitor.sh` was a `while true; sleep 60` loop started from
`autostart.lua` on every host, including desktops with no battery, calling a
script that shelled out to `acpi -b`. On `mac` that reports the Logitech mouse
as a second battery.

It is now `features/hardware/battery`: a systemd user timer gated on
`laptop.enable`, running a `writeShellApplication` that reads sysfs and skips
peripherals by their `scope` attribute. It survives a Hyprland restart, logs to
the journal, and does not exist at all on `pc`, `alpha` or `omega`.

### Earlier work

Desktop split (`hyprland`, `theme`, `cursor`, `webapps` as features, with
`~/.config/hypr` a single directory link), Quickshell's Tailnet host picker and
remote application launcher over Waypipe, the `windows-vm` feature, and the
deletion of Sunshine, Moonlight, Waybar, dunst, Eww and Wofi. See the git
history for detail; those areas are settled.

## What's left

### 1. Desktop shell

The moves are finished; this is build work, tracked in
`features/desktop/quickshell/TODO.md`.

- Bar and notification UI in Quickshell. Waybar and dunst are gone and nothing
  replaced them.
- Wallpapers. Nothing paints the background — chosen deliberately, the old shell
  was the renderer. `features/desktop/wallpaper/` still holds five scripts
  targeting three backends, one of which (`swww`) is not installed. Accent
  extraction died with Wofi and would need rebuilding for a themed Quickshell.
- Keybinding help menu from Hyprland's active binds.
- Verify a remote GUI launch between two physical machines; only localhost has
  been tested.
- Remote launch logs have no rotation.
- `TODO.md` still mentions a Sunshine menu; those helpers are deleted.

### 2. Still installed by hand

- **`hyprlog`, `hyprlogd` and `timeline-hyprfocusd-snitch` come from
  `~/.cargo/bin`.** `autostart.lua` starts two of them, and they only run where
  `cargo install` has been run. Left deliberately: hyprlog is being rewritten
  and will be packaged in `packages/` then. Marked `NOT REPRODUCIBLE` in
  `autostart.lua`.
- `~/Documents/Code/Hyprland/build` is no longer used by anything and can be
  deleted whenever convenient. Keep the checkout for development.

### 3. Build distribution

No Hyprland binary cache is configured, so `aquamarine`, `hyprutils`,
`hyprgraphics`, `hyprcursor`, `hyprlang` and `xdph` all compile from source on
every machine, even though upstream publishes them to `hyprland.cachix.org`.
Adding it needs `nix.settings.substituters` and `trusted-public-keys` on the
NixOS side. Four machines run the desktop, and `mac` is aarch64 so it cannot
share an x86 build at all.

### 4. Loose ends

- The packaged Hyprland reports `built from branch unknown ... dirty`, because
  the GitHub tarball carries no git metadata. Cosmetic.
- **`features/desktop/theme/` is deliberately not gated on `desktopEnv.enable`.**
  The headless machines run GUI programs such as Thunar displayed elsewhere over
  Waypipe, and those need the icon theme and the GTK/Qt hints. Do not "fix" it.
- `features/applications/handy/`'s data directory is not linked; only
  `settings_store.json` is. If Handy ever replaces that file instead of writing
  in place, activation will refuse to clobber it and it should stop being
  versioned.
- The webapps activation refreshes the icon and desktop databases, which is a
  no-op here because neither `gtk-update-icon-cache` nor `update-desktop-database`
  is on `PATH`. `symlink.sh` had the same guarded calls.

## Known issues not caused by the reorganization

- **The PAT in `~/.config/secrets/PAT` was pasted into a chat transcript and
  should be rotated.** Replace it without it touching shell history:
  `wl-paste > ~/.config/secrets/PAT && chmod 600 ~/.config/secrets/PAT`
  or `env -u GH_TOKEN gh auth token > ~/.config/secrets/PAT`. Then commit the
  secrets repo.
- **Screenshots blow out** when Hyprland's wallpaper blur is in frame. Capture
  itself is fixed and HDR-correct; the remaining issue is upstream Hyprland.

## Gotchas worth knowing

- **Nix flakes ignore untracked files.** After creating a feature or a host,
  `git add` it or the build fails with "Path ... is not tracked by Git". Nothing
  needs to be committed, only staged.
- **A directory link cannot replace a real directory.** Home Manager aborts
  instead. Check the directory holds nothing unmanaged, then delete it before
  activating. The hyprland feature does this itself in `hyprMigrateToSymlink`.
- **Stale symlinks abort activation.** Home Manager refuses to clobber them and
  stops partway. When moving a file, delete the old link first, and verify it is
  still a symlink and not a real file the application has since rewritten.
- **`set -e` and `&&` as the last command of a loop body.** A non-matching
  `[ ... ] && echo` at the end of a `while read` loop exits the subshell, which
  silently emptied `rehome`'s host lookup. Use `if`.
- **`pgrep -x quickshell` never matches.** The wrapped binary's process name is
  `.quickshell-wra`. Use `pgrep -f quickshell`.
- **Do not `pkill -f` a pattern that appears in your own command line.** It
  matches the shell running it and hangs.
- **Autostart runs `qs -d -n`.** The `-n` prevents duplicate instances on
  `hyprctl reload`.

## Verifying a change

```bash
nix build .#homeConfigurations.pc.activationPackage --no-link   # build one host
rehome                                                          # activate this one
```

Check every host still evaluates after touching anything shared:

```bash
for h in pc alpha omega legion mac t480s t470 zombie; do
  printf '%-8s ' "$h"
  nix eval --raw ".#homeConfigurations.$h.activationPackage.drvPath" >/dev/null 2>&1 \
    && echo OK || echo FAIL
done
```

To confirm a link resolves back into the repository rather than the store:

```bash
readlink -f ~/.config/<thing>
```
