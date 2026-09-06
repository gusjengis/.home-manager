# Reorganization Handoff

Status of the ongoing restructuring of this Home Manager configuration.

## The goal

One folder per feature. Opening a feature folder should show everything about
that feature: its Nix declaration, its config files, its scripts, its assets,
its services. No hunting across a parallel `config_files/` tree.

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

## Done

```
features/
├── agents/          opencode (config, plugins, state, caveman skills), claude-code, python
├── applications/    chromium, communication, mail, obsidian, onepassword
├── desktop/         quickshell, screenshots, wallpaper
├── development/     tools, game-development
├── files/           thunar, documents, default-apps, tailnet-bookmarks
├── gaming/
├── git/             git, gh, lazygit, GH_TOKEN wiring
├── java/            shared by gaming and development
├── media/           playback, creation
├── printing/bambu/
├── repo-sync/       packaged scripts, repo lists, boot service
├── secrets/         runtime env loading
├── ssh/             package, config, authorized_keys, key permissions
├── system-tools/    archives, connectivity, hardware, monitoring, shell, storage
└── terminal/        shell (bash/commands/tools), tmux, kitty, pipes-rs, rjmatrix

legacy/ambxst/       old shell, isolated, still launchable, not integrated
policy/              insecure package allowances, with owners documented
```

Deleted along the way: Thunderbird (replaced by Mailspring), Signal, Krita,
Swappy, all Eww configs and helper scripts, the Sunshine host picker, the
Waypipe launcher, the Eww calendar, `profile.webp`, empty `readme.md`, the
tracked `result` symlink, and the unused `stable-nixpkgs` flake input.

## What's left

### Latest progress: Quickshell remote launcher

- Quickshell now owns both the Tailnet host picker and remote app picker locally.
  `SUPER+SPACE` opens local apps; `SUPER+CTRL+SPACE` opens remote hosts.
- `features/desktop/quickshell/remote-apps.py` supplies JSON app metadata and
  embedded icons over SSH, then launches the selected desktop ID through Waypipe.
  Its Nix module installs the helper, Waypipe, and xwayland-satellite on each
  desktop host. Deploy this revision with `rehome` on both ends.
- Cancelled metadata requests terminate/reap their SSH process group. Remote
  app sessions are detached from Quickshell reloads; failures return through IPC.
- Waybar/dunst configs, their linker entries, Waybar binding/reload plumbing,
  and now-unused bar/media helper scripts have been removed with approval.
  Eww remains removed. Wofi remains for focus-lock confirmation.
- Verification: Home Manager build and `rehome` passed, 20 backend tests passed,
  Quickshell loaded and IPC menus were exercised, local export and SSH export
  through localhost passed (79 apps, 76 icons). A GTK display connection through
  Waypipe over localhost also passed. Physical-peer GUI launch needs verification
  after remote deployment. See the Quickshell roadmap for behavioral limits.

### 1. Desktop shell — the big one

`config_files/hypr/` is the largest remaining block. It holds the Hyprland Lua
config (`hyprland.lua`, `keybinds.lua`, `variables.lua`, `workspaces.lua`,
`appearance.lua`, `autostart.lua`), four `.conf` files, and 11 helper scripts.

Suggested split:

- `features/desktop/hyprland/` — the Lua graph, the `.conf` files, the
  platform-variables activation currently in `desktop_env/hyprland.nix`.
- `features/desktop/wofi/` — config, style, `terminal-runner.sh`.
- `features/desktop/theme/` — from `desktop_env/theme.nix`.
- `features/desktop/cursor/` — from `desktop_env/cursor.nix`, plus
  `config_files/wl-kbptr/config` which `keybinds.lua:123` uses directly.
- `features/desktop/webapps/` — the 17 `.desktop` entries, 14 icons, and
  `launch-desktop-entry.sh` / `launch-in-kitty.sh`. These are the last thing
  `symlink.sh` does with globs and icon-cache rebuilding, so this one needs
  care.

Once `desktop_env/` is empty, delete it and drop the import from `home.nix:22`.

**Shell direction confirmed:** use Quickshell instead of Waybar, dunst, and Eww.
Their old configs are removed; the bar and notification UI are still to be built.

Also stale: `hyprlog.conf` is linked and `autostart.lua:7` runs `hyprlogd`, but
the `hyprlog` package is commented out. `hyprpaper.conf` is linked and the
package installed, but nothing starts it. `hyprsunset.conf` is linked and
`autostart.lua:5` starts `hyprsunset`, but the package only comes from the
untracked `local.nix`.

Orphaned Hypr scripts with no caller found: `current-window.sh`,
`system-status.sh`, `open_chromium.sh` (commented out at `autostart.lua:14`).

### 2. Remote access

`modules/remote_streaming.nix` and `modules/windows_vm.nix` are the last two
files in `modules/`. Move to `features/remote/sunshine/` and
`features/remote/windows-vm/`, taking `scripts/sunshine-connect.sh`,
`scripts/sunshine-stream-host.sh`, and root `windows-logo.webp` with them.

`remote_streaming.nix:9-21` still wraps scripts that `exec` out of
`$HOME/.home-manager/scripts/`. Package them properly with `runtimeInputs`, the
same way `features/repo-sync/` now does.

Note that `windows_vm.nix` and `scripts/tailnet-thunar-bookmarks.sh` both
hardcode the same OG VM address, share name, and Tailnet host. Worth a shared
option rather than two copies.

### 3. Retire the last of the old mechanism

`scripts/symlink.sh` is down to Handy settings, wofi, the Hypr
files, plus the desktop-entry and icon glob logic. When those move, delete
`symlink.sh`, delete `link_files.nix`, and drop the import at `home.nix:27`.

Remaining loose scripts and their owners:

| Script | Owner |
|---|---|
| `battery-monitor.sh`, `battery-notify.sh` | `autostart.lua:10` — a laptop/power feature |
| `focus-lock.sh` | `keybinds.lua:159` — hyprland feature |
| `launch-desktop-entry.sh` | `variables.lua:6` — webapps feature |
| `launch-in-kitty.sh` | `btop.desktop`, `nvim.desktop` — webapps feature |
| `clean-broken-desktop-entries.sh` | no caller; manual tool, keep or delete |
| `sunshine-connect.sh`, `sunshine-stream-host.sh` | remote access feature |

`config_files/local/share/com.pais.handy/settings_store.json` belongs with
Handy, which is currently declared in `features/development/tools.nix`. It is
app-written state, so link the directory rather than the file.

### 4. Hosts and profiles

`home.nix` still mixes root imports, identity, feature options, the Helvetica
derivation, and a desktop-only `LD_LIBRARY_PATH`.

- Move the Helvetica derivation to `packages/helvetica-neue/` with `fonts/`.
- Move identity and option defaults to `hosts/gusjengis/`.
- `home.nix:29-30` imports `modules.nix` and `local.nix` by absolute path
  guarded on `pathExists`. Both are gitignored host-local files. Fold them into
  a proper host module.
- `flake.nix:69-70` calls every aarch64 machine `Mac` and every x86_64 machine
  `PC`. These are architecture flags wearing machine-name costumes, and they
  are threaded through modules as `specialArgs`. Consider renaming, or deriving
  real host identity instead.
- `flake.nix:50` falls back to `x86_64-linux` when `builtins.currentSystem` is
  unavailable, which is why `rehome` passes `--impure`.

### 5. Loose ends

- **`flake.nix` has two unused inputs**, `ortie` and `carillon`, both mail
  helpers with explanatory comments but no consumer. `hyprlog-nixpkgs` is
  passed through `specialArgs` but its only use is commented out.
- **`.gitignore` references `config_files/hypr/monitors.lua`**, which is
  correct today but will move with the Hyprland feature.
- **Quickshell rebuild list** is in `features/desktop/quickshell/TODO.md`:
  keybind help, wallpapers, bar/notifications, remaining Wofi controls, and
  remote-launch verification. Waypipe host/app menus are implemented.
- **`features/desktop/wallpaper/`** holds six scripts targeting three backends,
  one of which (`swww`) is not installed. Left unsorted deliberately; sort it
  out when Quickshell gains wallpaper support.

## Known issues not caused by the reorganization

- **The PAT in `~/.config/secrets/PAT` was pasted into a chat transcript and
  should be rotated.** Replace it without it touching shell history:
  `wl-paste > ~/.config/secrets/PAT && chmod 600 ~/.config/secrets/PAT`
  or `env -u GH_TOKEN gh auth token > ~/.config/secrets/PAT`. Then commit the
  secrets repo.
- **The NixOS side has an unrelated evaluation error.** `nodejs_24` and `nil`
  were added to `/etc/nix-modules/software/nvim.nix` (Rust was already there),
  but the system will not build until this is fixed:
  `Module '/etc/nixos/windows-vm.nix' has an unsupported attribute
  'virtual-machines'` — it needs a top-level `config`/`options` attribute
  removed. Until then Node and nil are on neither the system nor Home Manager.
- **Nothing paints the desktop background.** Chosen deliberately; the old shell
  was the renderer.
- **Screenshots blow out** when Hyprland's wallpaper blur is in frame. Capture
  itself is fixed and HDR-correct; the remaining issue is upstream Hyprland.

## Gotchas worth knowing

- **Nix flakes ignore untracked files.** After creating a feature, `git add` it
  or the build fails with "Path ... is not tracked by Git". Nothing needs to be
  committed, only staged.
- **Migrating a file off `symlink.sh` leaves a stale symlink** pointing at the
  old `config_files/` path. Home Manager refuses to clobber it and aborts
  activation partway. Delete the stale link first, and verify it is still a
  symlink and not a real file the app has since rewritten.
- **`pgrep -x quickshell` never matches.** The wrapped binary's process name is
  `.quickshell-wra`. Use `pgrep -f quickshell`.
- **Do not `pkill -f` a pattern that appears in your own command line.** It
  matches the shell running it and hangs.
- **Autostart runs `qs -d -n`.** The `-n` prevents duplicate instances on
  `hyprctl reload`.

## Verifying a change

```bash
nix build .#homeConfigurations.gusjengis.activationPackage --no-link   # build only
rehome                                                                 # activate
```

To confirm a link resolves back into the repository rather than the store:

```bash
readlink -f ~/.config/<thing>
```
