# LightDM Slick Greeter - dwm-jangir

The dwm-jangir login screen is a small, version-pinned GTK/Vala overlay for
Fedora's Slick Greeter 2.2.6. It provides a compact dark login card, a
desktop-session selector, centered date/time and a solar timeline, plus
bottom-corner status/actions. It does not force a display mode or alter
LightDM authentication or session handling.
A modern Fedora LightDM login screen using Slick Greeter with a Nord colour
palette, blurred background, and the MesloLGS NF font.

The Fedora installer uses `slick-greeter`. The dwm-jangir LightDM install target
renders the matching Fedora `lightdm.conf`.

## Files

| File | Destination |
|------|-------------|
| `lightdm.conf` | `/etc/lightdm/lightdm.conf` |
| `slick-greeter.conf` | `/etc/lightdm/slick-greeter.conf` |
| `dwm-jangir-slick-greeter` | `/usr/libexec/dwm-jangir-slick-greeter` |
| `dwm-jangir-slick-greeter.desktop` | `/usr/share/xgreeters/dwm-jangir-slick-greeter.desktop` |
| `theme/` | `/usr/share/themes/dwm-jangir-dark/` |
| `wallpapers/` | `/usr/share/dwm-jangir/lightdm-backgrounds/` |
| `assets/dwm.svg` | `/usr/share/dwm-jangir/lightdm-assets/dwm.svg` |
| `rpm/` | Builder for `/usr/libexec/dwm-jangir-slick-greeter-bin` |

`wallpapers/SOURCES.md` records the upstream source for each bundled image.

The branded patch implements one consistent seven-state login flow: default,
password focus, invalid-password feedback, desktop-session selection, the
power menu, shutdown/restart confirmation, and the signing-in state. The
authentication status row is created only while feedback is visible, keeping
the default card compact while errors and signing-in feedback have room.

The large clock also shows the local date and, when networking is available,
a compact sunrise/sunset timeline. Solar times are fetched from the free
`wttr.in` endpoint without an API key in a background worker, with a
four-second timeout and a fifteen-minute refresh interval. It shows one next
solar event, using the sun by day and a moon by night. If the request fails,
the greeter keeps working and simply hides the solar panel.

The greeter also applies a lightweight, deterministic code-pattern and
film-grain veil below the GTK controls. It preserves the random-wallpaper
selection logic without making a wallpaper the visible UI surface. Keep these
effects static and low-cost; do not introduce full-screen per-frame redraws.

## Session inventory and UI maintenance

LightDM lists real `.desktop` files from `/usr/share/xsessions/` (and, where
used, `/usr/share/wayland-sessions/`). Do not leave test-only desktop entries
installed: they appear as real login choices. Remove or move an exactly
identified test entry only after confirming the real `dwm-jangir.desktop`
entry remains.

The source of truth for GTK/Vala UI changes is
`rpm/patches/0001-dwm-jangir-greeter-ui.patch`, not the installed binary.
Recreate the patch from the pinned Slick Greeter source, run the LightDM
configuration test, build/install the RPM, restart LightDM, and inspect the
actual `1920x1080` VM render. The solar timeline intentionally redraws at a
modest six FPS; check that the active greeter remains lightweight before
handoff.

## Build the patched greeter RPM

The UI patch targets exactly Slick Greeter 2.2.6, matching Fedora 44. Build it
before installing the LightDM assets:

```sh
sudo dnf install \
  meson vala gettext-devel intltool desktop-file-utils \
  gtk3-devel lightdm-devel libcanberra-devel xapp-devel rpm-build
make -C lightdm rpm
sudo dnf install ~/rpmbuild/RPMS/*/dwm-jangir-slick-greeter-2.2.6-1*.rpm
```

The build helper downloads the version-pinned upstream source only when it is
not already present in `$RPM_TOPDIR/SOURCES`, and verifies its SHA-256 before
building. It installs only the patched executable; Fedora's `slick-greeter`
package continues to supply the schemas and shared data.
| `wallpaper.jpg` | `/usr/share/pixmaps/dwm-jangir.jpg` |

## Install

The main `install.sh` installs the LightDM configuration and assets. To apply
them manually after the RPM is installed:

```sh
sudo make install
```

The direct `make install` defaults match Fedora. Prefer the top-level
`install.sh` for a complete installation.

## Customisation

Edit `slick-greeter.conf` before running `sudo make install`:

- **background** — the runtime symlink managed by the wrapper
- **font-name** — a font available to the greeter user
- **show-hostname** / **show-quit** — the minimal panel controls
- **activate-numlock** — enable only when `numlockx` is installed

Do not add `display-setup-script` or a static `xrandr` command to LightDM.
Use `dwm-display-setup` from an X11 session for persistent display settings.

## Verification checklist

- The login screen renders at the expected `1920x1080` VM resolution.
- The DWM selector shows the DWM mark and opens the session picker.
- Every remaining real desktop session can be selected and launched; no
  temporary/test desktop session is listed.
- Invalid passwords and signing-in feedback remain readable below the entry.
- Bottom-right Suspend, Restart, and Shut Down controls each request
  confirmation before action.
- `systemctl is-active lightdm` succeeds and the current-boot LightDM journal
  has no new warnings or errors after the test restart.
