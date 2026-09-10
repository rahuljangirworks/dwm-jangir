---
title: DWM-Jangir Project State
type: live-project-state
project: dwm-jangir
status: active
last-verified: 2026-09-10
---

# DWM-Jangir Project State

Read `AGENTS.md`, `FORK.md`, and `FORK-DELTA.md` before changing this fork.
This record contains verified current facts only.

## Verified Upstream Sync

| Item | Value |
| --- | --- |
| Integration branch | `sync/2026-09-10` |
| Upstream base | `40cbdc8` (`feat(branding): add dark Anaconda installer branding and dynamic version generator`) |
| Sync implementation | `8ed5ed4` |
| Result before this state record | 41 fork commits above `upstream/main`, 0 upstream commits missing |
| Target branch | local `dev` after fast-forward; not pushed to `origin` |
| Legacy branch | `main`; do not start new work there |

The sync imports the upstream Phase 6 system-management work, docked/undocked
display profiles, relative monitor placement, `dwmterm`, and Anaconda branding.
It retains only D-001 through D-007: Rahul panel branding, the `dwm-jangir`
runtime identity, generic NVIDIA MetaModes, the minimal D-Bus session wrapper,
and the opt-in Dell 5820 profile.

The fork-specific patched LightDM greeter, custom RPM, wallpapers, and visual
overlay were removed. The active configuration uses upstream `slick-greeter`
with `user-session=dwm-jangir`; `dwm.desktop` is only a compatibility symlink
to `dwm-jangir.desktop`.

## Validation

Passed locally:

- `git diff --check`, build, and `make check-shell`.
- Runtime identity, LightDM rendering, display setup, Dell profile,
  installer preservation, terminal, Fedora ISO builder, staged install/uninstall
  manifest, accessibility, panel-settings, and input-settings tests.
- The two fork-namespace system-management digest tests.

Not fully validated here:

- The full system-management suite has 14 errors and one related failure
  because `PackageKitGlib 1.0` Python bindings are not installed in this
  workspace; the unrelated PackageKit repository-read cases therefore cannot
  initialize. Run it on a Fedora environment with those bindings.
- `shfmt`, `qmllint`, Xvfb, and a real Fedora/X11 login session are unavailable.
  Run formatting, QML/Xvfb, and live login validation before release.

## Next Action

Review the final diff, run the unavailable Fedora validation where possible,
then push `dev` only with maintainer approval. Do not force-push or modify the
read-only upstream remote.
