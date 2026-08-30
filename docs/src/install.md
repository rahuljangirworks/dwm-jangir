# Fedora Installation

> **dwm-jangir is Fedora-only.** Fedora Linux with Xorg is required for every
> supported installation, package, test, and release path.

## Quick Install (Recommended)

The easiest way is via [Linutil](https://christitus.com/linux):

```bash
curl -fsSL https://christitus.com/linux | sh
```

In the TUI, press `v` to multi-select, then select **dwm**, **bash prompt**,
and **alacritty**. Press `Enter` to install.

Herdr is optional. To add its checksum-verified helper after the Linutil path,
run:

```bash
install-herdr
```

![linutil-appinstall](images/linutil-applications.png)

## Manual Install

### 1. Dependencies

The supported dependency path is the installer because it resolves Fedora
package names from the shared map:

```bash
./install.sh --dry-run --non-interactive --profile core
./install.sh --profile full
```

Use `core` for the required build/X11/session packages and Alacritty,
`recommended` for the complete desktop layer, or `full` for optional extras
such as file-manager integration, keyring login integration, wallpapers, and
display-manager setup. On x86_64 Fedora, `full` can also install Steam,
Gamescope, GameMode, and MangoHud after repository approval.
The installer separately asks before enabling the `rahuljangirworks/copr-fedora`
COPR for patched Gamescope and RPM Fusion nonfree for Steam. Declining skips the
gaming subset without affecting other full-profile extras.
When the optional wallpaper directory is absent, `full` clones the Nord
wallpapers from `https://github.com/rahuljangirworks/background`.

### 2. Clone and Build

```bash
git clone https://github.com/rahuljangirworks/dwm-jangir.git
cd dwm-jangir
cp config.def.h config.h
./scripts/dev-sync-install.sh
```

For later source-checkout updates, run the same command so the binary,
installed helpers, managed Quickshell configuration, and data copy stay at one
revision. Run `./scripts/dev-sync-install.sh --check` after any requested
session restart to verify the active runtime.

### Automated Installer

```bash
./install.sh
```

The script requires `ID=fedora` before handling dependency installation, font
copying, display-manager integration, or config placement. Every other
operating-system identity is rejected before changes are made.
Existing user configuration and `.xinitrc` files are preserved. Upgrades remove
the known legacy `dwm-graphical-session.service` and
`wm-graphical-session.service` early-start configuration so XDG applications
start only after the X11 display environment is available; customized user
units are disabled from early startup but otherwise preserved.

System files are installed with `sudo`, while configuration and data under the
user's XDG directories are installed as that user.

### Runtime identity migration

The active installed identity is `dwm-jangir`. A normal installer run first
installs the new session and privileged helper, then migrates unambiguous
legacy `dwm-titus` XDG configuration, data, and state directories to
`dwm-jangir`. It also renames the managed Xorg fragment to
`/etc/X11/xorg.conf.d/90-dwm-jangir-display.conf`. If both user directories or
both Xorg fragments exist and differ, the installer preserves both and prints a
warning; review the differences before rebooting rather than losing settings.

After a successful migration, select **dwm-jangir** in LightDM. The legacy
`dwm` session entry is removed only when it is the project's former entry.

If a v0.6.0 Fedora image left the default XDG parents owned by root, first
verify that none of them is a symbolic link, then repair only those parents and
rerun the installer:

```bash
xdg_parents=()
for path in "$HOME/.local" "$HOME/.local/share" "$HOME/.config"; do
    test ! -L "$path" || {
        printf 'Refusing symbolic link: %s\n' "$path" >&2
        exit 1
    }
    test -e "$path" || continue
    test -d "$path" || { printf 'Refusing non-directory: %s\n' "$path" >&2; exit 1; }
    xdg_parents+=("$path")
done
((${#xdg_parents[@]} == 0)) || sudo chown "$(id -u):$(id -g)" -- "${xdg_parents[@]}"
./install.sh
```

This repair is intentionally non-recursive so it does not change unrelated
user files.

Every profile and Fedora image defaults to Alacritty without Herdr. With the
explicit `--install-herdr` option, the repository downloads the official
`https://herdr.dev/install.sh` into an isolated staging directory and verifies
repository-pinned SHA-256 checksums for both that installer and its resulting
Herdr binary before copying it into `~/.local/bin`. A checksum mismatch or
network failure leaves Alacritty usable and reports the Herdr failure. When the
`codex` or `claude` command is already available, the helper also runs Herdr's
matching `integration install` command so native Codex and Claude Code sessions
can be restored. Integration failures are reported separately from binary
installation failures.

When matching vendor XDG entries exist for Picom, the polkit agent, or Light
Locker, the installer copies each entry to the user autostart directory and
adds only the dwm session exclusion. Original commands and vendor session
guards remain intact, no entry is created when the vendor entry is absent, and
existing user entries are preserved.

Installer package profiles are selected with `DWM_INSTALL_PROFILE`:

- `core`: required build packages, X11/session runtime, and Alacritty. Herdr is
  skipped unless `--install-herdr` is provided.
- `recommended`: `core` plus the recommended desktop layer such as Quickshell,
  Picom, Feh, Dex, fonts, theming, screenshot, audio, Bluetooth control and
  tray tools, brightness tools, Flatpak, and the GTK desktop portal. It also
  adds Flathub for the target user, installs Gear Lever as the default AppImage
  manager, installs the available Fedora GTK theme packages, and installs
  Nordic system-wide for the default Nord theme.
- `full`: `recommended` plus optional extras such as Thunar with SMB-share
  browsing, network tray utilities, keyring login integration,
  wallpapers, and display-manager setup. x86_64 Fedora full installs also
  include Steam, Gamescope, and 64-bit and 32-bit GameMode and MangoHud support
  after separate repository approval.
  The installer enables the `rahuljangirworks/copr-fedora` COPR for Gamescope and
  RPM Fusion nonfree for Steam, then adds the invoking user to the `gamemode`
  group; log out and back in before using its privileged tuning helpers.

The default is `full` to preserve the historical automated installer behavior.
If `maim` is unavailable in the enabled Fedora repositories, the installer
skips that add-on instead of failing the desktop install and reports that the
screenshot hotkeys are unavailable.

For a minimal install:

```bash
DWM_INSTALL_PROFILE=core ./install.sh
```

The same profile can be selected with a flag:

```bash
./install.sh --profile core
```

Interactive runs print the resolved package plan before prompting. For CI,
packaging checks, or scripted validation, use the non-interactive flags:

```bash
./install.sh --dry-run --non-interactive --profile core
./install.sh --non-interactive --yes --profile recommended
./install.sh --non-interactive --yes --profile full --enable-fedora-gaming-repos
```

Without `--enable-fedora-gaming-repos`, unattended Fedora full installs skip
Steam, Gamescope, GameMode, and MangoHud rather than changing repository trust.

Herdr is skipped for every profile unless `--install-herdr` or
`DWM_INSTALL_HERDR=true` is provided. Its published Linux binaries support
x86_64 and aarch64. Installation alone does not change the terminal default;
set `DWM_HERDR=1` and run `dwm-terminal` to enter the optional workspace.
Herdr can also be installed or repaired separately:

```bash
install-herdr
install-herdr --force
```

Upgrades preserve an existing `hotkeys.toml`. If an earlier installer seeded
its `terminal` variable to `dwm-terminal`, set it to `alacritty` to adopt the
current direct-terminal default. The installer does not overwrite that
user-owned choice.

### Installer diagnostic record

Every non-dry-run installer run writes one user-owned record to:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/dwm-jangir/install-last.log
```

It contains the read-only preflight inspection, full installer output, and the
final result. The file is replaced atomically only after a run finishes, so it
always represents the last completed install attempt and does not accumulate a
long history. Share the relevant part of this file with an agent when an
install fails. `--dry-run` does not replace the previous record. Set
`DWM_INSTALL_LOG=0` only when you explicitly do not want an install record.

## Starting dwm

**Display manager** (SDDM, GDM, LightDM): log out and select **dwm** from the session list.

When the interactive installer runs inside an active X11 session, it offers
the `dwm-display-setup` wizard after installation. The wizard previews the
chosen resolution and multi-monitor layout, then installs a backed-up Xorg
fragment. Automatic horizontal placement is the default: the selected primary
display is placed at `0x0`, then remaining enabled displays are arranged to its
right using their rotation-aware size. Select manual placement to enter X/Y
coordinates instead. Installations run from a TTY or in non-interactive mode defer this
step; after the first X11 login, run:

```bash
dwm-display-setup
```

### Dell Precision 5820 display profile (opt-in)

`dell-5820` is a personal profile for Rahul's DP-0 and DVI-D-0 wiring; it is
not part of the generic installer path and is never auto-detected. Select it
explicitly:

```bash
./install.sh --display-profile dell-5820
```

The installer copies the profile to
`${XDG_CONFIG_HOME:-$HOME/.config}/dwm-jangir/display-profiles/dell-5820.conf`.
In an active X11 session it confirms the two required outputs are connected,
then uses `dwm-display-setup` to preview and persist the configuration. A TTY
install stores the profile but does not apply it. On any output mismatch, it
does not change Xorg; use `dwm-display-setup` after logging in for the normal
wizard.

The installed Settings display provider is machine-oriented. Its actions are:

```text
dwm-settings-display discover
dwm-settings-display watch
dwm-settings-display save NAME SPEC...
dwm-settings-display preview TOKEN SECONDS SPEC...
dwm-settings-display preview-profile TOKEN SECONDS NAME
dwm-settings-display keep TOKEN [NAME]
dwm-settings-display revert TOKEN
dwm-settings-display preview-status [TOKEN]
dwm-settings-display install-profile NAME
dwm-settings-display rollback-system
```

Discovery and live previews require `xrandr`, and the hotplug watch requires
`udevadm`. Persistent install and rollback additionally require `pkexec` plus
the root-owned helper installed at `${PREFIX}/libexec/dwm-jangir/`. Profiles are
stored under
`${XDG_CONFIG_HOME:-$HOME/.config}/dwm-jangir/display-profiles/`. No move is
needed for profiles created by `dwm-display-profile`, which uses the same
directory. If `DWM_DISPLAY_PROFILE_DIR` previously pointed elsewhere, either
keep that environment override or move those `.conf` files into the default
directory before using Settings.

The input provider exposes the corresponding session actions:

```text
dwm-settings-input discover
dwm-settings-input watch
dwm-settings-input watch-apply
dwm-settings-input apply-saved
dwm-settings-input preview TOKEN SECONDS DEVICE SETTING VALUE
dwm-settings-input keep TOKEN
dwm-settings-input revert TOKEN
dwm-settings-input preview-status [TOKEN]
dwm-settings-input reset DEVICE SETTING
```

All input actions require `xinput`; keyboard layout and modifier operations
also require `setxkbmap`; stable hardware identity and hotplug watching use
`udevadm`, and the session watcher uses `flock` from `util-linux` to prevent
duplicate replay workers. Kept values default to
`${XDG_CONFIG_HOME:-$HOME/.config}/dwm-jangir/input-settings.conf`. Set
`DWM_INPUT_SETTINGS_FILE` to use a different file. The normal session startup
invokes `apply-saved` idempotently and runs `watch-apply` to debounce input
hotplug events before replaying saved values for returning devices.

**startx:**
```bash
startx
```

The provided `.xinitrc` disables screen blanking, starts the configured Quickshell panel, and runs dwm.

## Minimal Session Profile

The minimal supported profile is useful for lean Fedora systems, recovery
sessions, and minimal Fedora qualification. It keeps only:

- an X11 server and either a display-manager session or `startx`
- D-Bus session support
- `dwm`
- Alacritty as the default terminal, with `dwm-terminal` available to delegated
  tools that require fallback selection
- required X11 helpers used by core startup and display commands, such as
  `xrandr`, `xset`, and `xsetroot`

Quickshell, Picom, Feh, Dex, a polkit agent, screenshot tools, wallpapers, tray
utilities, and audio or brightness helpers are optional in this profile.
Missing optional components should appear as degraded features in
`dwm-diagnostics`, not as session-fatal failures.

For `startx`, a minimal `.xinitrc` can be:

```sh
#!/bin/sh
xset s off
xset -dpms
xsetroot -cursor_name left_ptr
exec dbus-run-session dwm
```

If the login path already creates a user D-Bus session, use `exec dwm`
instead of wrapping it with `dbus-run-session`.

After installation, verify the profile with:

```bash
dwm-diagnostics
dwm-terminal --print-command
```

`dwm-diagnostics` must report zero required failures before treating the
minimal profile as ready. Optional degraded features can remain unresolved.
The default binding opens Alacritty directly. A plain `dwm-terminal` also opens
the selected emulator directly unless `DWM_HERDR=1` explicitly enables Herdr.
Commands such as `dwm-terminal -e sh -c 'command'` always bypass Herdr.
