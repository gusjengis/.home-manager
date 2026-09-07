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
├── applications/    chromium, communication, handy, mail, obsidian, onepassword
├── desktop/         cursor, hyprland, quickshell, screenshots, theme, wallpaper,
│                    webapps
├── development/     tools, game-development
├── files/           thunar, documents, default-apps, tailnet-bookmarks
├── gaming/
├── git/             git, gh, lazygit, GH_TOKEN wiring
├── java/            shared by gaming and development
├── media/           playback, creation
├── printing/bambu/
├── remote/          windows-vm (RDP launchers, OG on-demand start)
├── repo-sync/       packaged scripts, repo lists, boot service
├── secrets/         runtime env loading
├── ssh/             package, config, authorized_keys, key permissions
├── system-tools/    archives, connectivity, hardware, monitoring, shell, storage
└── terminal/        shell (bash/commands/tools), tmux, kitty, pipes-rs, rjmatrix

legacy/ambxst/       old shell, isolated, still launchable, not integrated
policy/              insecure package allowances, with owners documented
```

Deleted along the way: Thunderbird (replaced by Mailspring), Signal, Krita,
Swappy, all Eww configs and helper scripts, Wofi and the accent pipeline, all of
Sunshine and Moonlight, the Waypipe launcher, the Eww calendar, `profile.webp`,
empty `readme.md`, the tracked `result` symlink, and the unused `stable-nixpkgs`
flake input.

The old deployment mechanism is gone: `scripts/symlink.sh`, `link_files.nix`,
and the whole `config_files/` tree have been deleted. `modules/` is gone too.
Every configuration file is now owned by the feature that uses it.

## What's left

### Latest progress: remote access, Sunshine deleted

- Sunshine and Moonlight are gone: `modules/remote_streaming.nix`,
  `sunshine-connect.sh`, `sunshine-stream-host.sh`, the `moonlight-qt` package,
  the `remoteStreaming.enable` option, and the `pcstream` alias. Nothing in this
  repository referenced them elsewhere.
- `features/remote/windows-vm/` owns the RDP launchers and `windows-logo.webp`.
  Both `windows-rdp` and `og-rdp` were already packaged with `writeShellApplication`
  and explicit `runtimeInputs`, so nothing needed repackaging, unlike the Sunshine
  wrappers that used to `exec` out of `scripts/`.
- The OG VM's address, user, SSH host, and SMB share now live in one place. The
  Thunar bookmark service reads them from `windowsVm.og` instead of repeating
  them, and a new `windowsVm.og.smbShare` option carries the share name. The
  generated unit environment is byte-identical to before.
- `modules/` and `modules/mod.nix` are deleted, with the `home.nix` import.
- Verification: build, `rehome`, `windows-rdp` and `og-rdp` on `PATH`, both
  desktop entries and the icon deployed, the OG launcher still reads its
  credentials file and execs `xfreerdp` through `/args-from:fd:3`, the bookmarks
  service stayed active with unchanged OG environment, and the Sunshine helpers
  and `pcstream` are gone.
- Note: `sunshine.service` still exists as a user unit from the NixOS side, and a
  Flatpak Sunshine unit is linked. Neither is controlled by this repository.
  `~/.config/secrets/` has no Sunshine entry to clean up.

### Earlier: desktop_env retired, linker deleted

- `features/desktop/theme/` and `features/desktop/cursor/` came from
  `desktop_env/`, which is now deleted along with its `home.nix` import.
  `wl-kbptr.conf` moved in with cursor. It needs no link: nothing reads
  `~/.config/wl-kbptr`, since `keybinds.lua` passes the repository path to `-c`.
- `features/desktop/webapps/` owns the 17 desktop entries, 14 icons, and both
  launcher scripts. Links are per file, because `~/.local/share/applications`
  and the icon directory are shared with Steam, Lutris, wine, and Home Manager's
  own `og-vm.desktop`. The entry list is read from the directory, so adding a
  webapp needs no Nix edit.
- `webapp-*` entries and icons follow `desktopEnv.enable`; `btop`, `nvim`, and
  `chromium-browser` do not, because `features/files/default-apps/mimeapps.list`
  names them as handlers. That reproduces what `symlink.sh` did with its
  `DESKTOP_ENV_ENABLED` unlink loop, using generation cleanup instead.
- `features/applications/handy/` took the package from `development/tools.nix`.
  Contrary to the earlier note here, its data directory is **not** linked:
  `~/.local/share/com.pais.handy` is 2.4 MB of recordings, models, `history.db`,
  and WebKit caches. Only `settings_store.json` is linked, so if Handy ever
  replaces that file instead of writing in place, activation will refuse to
  clobber it and the file should stop being versioned.
- Wofi and the accent pipeline are deleted: its config, `style.css`,
  `terminal-runner.sh`, `update-accent.sh`, the four wallpaper-cycler calls, the
  `ensureAccentCacheFile` activation, and the `wofi` and `wallust` packages.
  Nothing had called Wofi since Quickshell took `SUPER+SPACE` and `focus-lock.sh`
  was removed. Note that `wofi` is still on `PATH` from the NixOS side, in
  `/etc/nix-modules`, which this repository does not control.
- Verification: build, `rehome`, all 17 entries and 14 icons resolve into the
  repository, unmanaged neighbours survived (33 entries remain in the directory),
  `xdg-mime query default` still answers `nvim.desktop` and
  `chromium-browser.desktop`, Handy's settings link resolves while its data
  directory is untouched, `hyprctl reload` is clean at 73 binds, and `wallust`
  is gone from `PATH`.
- Note: the icon and desktop-database refresh in the webapps activation is a
  no-op on this host, since neither `gtk-update-icon-cache` nor
  `update-desktop-database` is on `PATH`. `symlink.sh` had the same guarded
  calls, so this is not a regression, and icon lookup works without them.

### Earlier: Hyprland feature

- `features/desktop/hyprland/` now owns the module that was
  `desktop_env/hyprland.nix`, plus `config/`, which is exactly the contents of
  `~/.config/hypr`: the Lua graph, the four `.conf` files, `scripts/`, and
  host-local `monitors.lua`.
- `~/.config/hypr` is a single out-of-store symlink to
  `features/desktop/hyprland/config`, replacing 11 `scripts/symlink.sh` entries.
  New Hypr files need no Nix change, and files written by hand land in the
  repository immediately. `default.nix` sits outside `config/` so it is not
  exposed as Hypr configuration.
- `monitors.lua` never reaches the store, since the directory link is resolved
  at runtime rather than by Nix.
- `platform-variables.lua` is chosen by `Mac`/`PC` in activation, as a symlink
  inside `config/` rather than a separate link in `~/.config/hypr`, which the
  directory link makes impossible. It is gitignored, like `monitors.lua`.
- Deleted: `focus-lock.sh` with its `SUPER+SHIFT+F4` submap and `CTRL+ESCAPE`
  bind, and `system-status.sh`.
- Behavior change, deliberate: Hypr config is now gated on `desktopEnv.enable`.
  The old linker deployed it on every host.
- Verification: build, `rehome`, `~/.config/hypr` resolves into the repository,
  writes through the link land in the repository, `hyprctl reload` returned ok,
  binds dropped 75 to 73 with no `focus_lock` submap left, Slack and Discord
  binds still resolve through `platform-variables`, and the monitor stayed at
  3840x2160@144.
- The old `~/.config/hypr` was deleted before activation because a directory
  link cannot replace a real directory. It held no regular files, only stale
  links: the previous generation's, a long-broken `hyprfocus.conf`, and
  `scripts/which-key.sh` and `shaders/crt.frag`, both pointing at files that
  never existed in this repository.

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
  Eww remains removed. Wofi has since been deleted too.
- Verification: Home Manager build and `rehome` passed, 20 backend tests passed,
  Quickshell loaded and IPC menus were exercised, local export and SSH export
  through localhost passed (79 apps, 76 icons). A GTK display connection through
  Waypipe over localhost also passed. Physical-peer GUI launch needs verification
  after remote deployment. See the Quickshell roadmap for behavioral limits.

### 1. Desktop shell — mostly done

The split is finished: hyprland, theme, cursor, and webapps are all features,
and `desktop_env/` is gone. What remains here is shell UI work, not moves.

**Shell direction confirmed:** use Quickshell instead of Waybar, dunst, and Eww.
Their old configs are removed; the bar and notification UI are still to be built.

Also stale: `hyprlog.conf` is linked and `autostart.lua:7` runs `hyprlogd`, but
the `hyprlog` package is commented out. `hyprpaper.conf` is linked and the
package installed, but nothing starts it. `hyprsunset.conf` is linked and
`autostart.lua:5` starts `hyprsunset`, but the package only comes from the
untracked `local.nix`.

Orphaned Hypr scripts with no caller, now in
`features/desktop/hyprland/config/scripts/`: `current-window.sh` and
`open_chromium.sh` (commented out at `autostart.lua:13`). They ride along with
the directory link, so they now land in `~/.config/hypr/scripts/`.
`system-status.sh` was deleted.

### 2. Remote access — done

`features/remote/windows-vm/` owns the RDP launchers, and `modules/` is gone.
Sunshine and Moonlight were deleted rather than moved.

### 3. Retire the last of the old mechanism — done

`scripts/symlink.sh`, `link_files.nix`, its `home.nix` import, and the
`config_files/` tree are deleted. `scripts/` is down to three files:

| Script | Owner |
|---|---|
| `battery-monitor.sh`, `battery-notify.sh` | `autostart.lua:10` — a laptop/power feature |
| `clean-broken-desktop-entries.sh` | no caller; manual tool, keep or delete |

Once those move or go, `scripts/` disappears too.

### 4. Hosts and profiles

`home.nix` still mixes root imports, identity, feature options, the Helvetica
derivation, and a desktop-only `LD_LIBRARY_PATH`.

- Move the Helvetica derivation to `packages/helvetica-neue/` with `fonts/`.
- Move identity and option defaults to `hosts/gusjengis/`.
- `home.nix:26-27` imports `modules.nix` and `local.nix` by absolute path
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
- **`.gitignore` and `.rgignore` now point at
  `features/desktop/hyprland/config/monitors.lua`.** Keep it and
  `config/platform-variables.lua` untracked; the directory link resolves them at
  runtime so they never reach the store.
- **Quickshell rebuild list** is in `features/desktop/quickshell/TODO.md`:
  keybind help, wallpapers, bar/notifications, and remote-launch verification.
  Waypipe host/app menus are implemented.
- **`features/desktop/wallpaper/`** holds five scripts targeting three backends,
  one of which (`swww`) is not installed. Left unsorted deliberately; sort it
  out when Quickshell gains wallpaper support. Accent extraction is gone with
  Wofi, so a themed Quickshell would need it rebuilt.
- **`features/desktop/theme/` is not gated on `desktopEnv.enable`**, unlike
  cursor, hyprland, and webapps. Preserved as it was; worth deciding on.

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
- **The old linker left stale symlinks** pointing at `config_files/` paths. Home
  Manager refuses to clobber them and aborts activation partway. They were all
  cleared during the migration, but the same rule applies to any future move:
  delete the stale link first, and verify it is still a symlink and not a real
  file the app has since rewritten.
- **A directory link cannot replace a real directory.** Home Manager aborts
  instead. Check the directory holds nothing unmanaged, then delete it before
  activating.
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
