# LightDM greeters

`dwm-jangir` supports two Fedora LightDM greeter themes. The upstream Slick
Greeter configuration is the default; Solar is a deliberately opt-in,
image-free alternate theme based on the validated VM1 design.

| Theme | Greeter session | What it provides |
| --- | --- | --- |
| `stock` (default) | `slick-greeter` | Fedora's packaged Slick Greeter, a Nord wallpaper, project logo, and normal Slick controls. |
| `solar` (opt-in) | `dwm-jangir-slick-greeter` | A pinned Slick Greeter 2.2.6 overlay that paints line/grain patterns, a local clock, and a solar timeline. It does not install or select wallpaper backgrounds. |

## Installer use

For a new installation, omit the flag to retain the upstream default:

```sh
./install.sh --profile full
```

Select Solar explicitly:

```sh
./install.sh --profile full --lightdm-theme solar
```

An installer re-run without `--lightdm-theme` preserves an existing Solar
selection. Choose `--lightdm-theme stock` to return to the upstream greeter.
Switching to stock changes only the active LightDM configuration; it retains
the Solar RPM and files so an administrator can switch back without deleting
anything.

Solar is version-pinned to Fedora `slick-greeter` **2.2.6**. The installer
checks that version, installs the required build dependencies, builds the local
`dwm-jangir-slick-greeter` RPM, and fails clearly if the Fedora package is not
compatible. It never silently falls back to a different binary.

The Solar weather/timeline data is optional. Its background worker contacts
`wttr.in` without an API key, uses a two-second connection timeout and a
four-second total timeout, refreshes every fifteen minutes, and hides the
timeline panel when data is unavailable. Authentication and login continue
without network access.

## Files and manual staging

`make -C lightdm install` defaults to `LIGHTDM_THEME=stock`. For a disposable
staging root, render either configuration with:

```sh
make -C lightdm DESTDIR=/tmp/dwm-lightdm-stock install
make -C lightdm DESTDIR=/tmp/dwm-lightdm-solar LIGHTDM_THEME=solar install
```

Solar's wrapper, xgreeter desktop entry, session icons, and GTK theme are
installed only for the Solar target. The patched executable itself is supplied
by `lightdm/rpm/dwm-jangir-slick-greeter.spec`; use the project installer to
build and install it, rather than pointing a live LightDM configuration at an
unbuilt wrapper.

Run the focused renderer test after a LightDM change:

```sh
./tests/test-lightdm-config.sh
```
