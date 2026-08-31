# LightDM Slick Greeter - dwm-jangir

The dwm-jangir login screen is a small, version-pinned overlay for Fedora's
Slick Greeter 2.2.6. It provides a compact dark login card, a desktop-session
selector, a minimal hostname/power panel, and a random local background chosen
at each greeter start. It does not force a display mode or make network calls
from the login screen.

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
