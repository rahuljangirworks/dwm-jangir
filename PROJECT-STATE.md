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
| Current integration branch | local `dev` at `fa8d624` (`merge: sync upstream 2026-09-10`) |
| Sync branch | `sync/2026-09-10` |
| Upstream base | `40cbdc8` (`feat(branding): add dark Anaconda installer branding and dynamic version generator`) |
| Sync implementation | `8ed5ed4` |
| Conflict resolution | Code and configuration match `sync/2026-09-10`; this state record and the delta ledger record the local merge |
| Upstream ancestry | no commits missing from `upstream/main`; historical `dev` ancestry is retained by the merge |
| Publication | merged locally; not pushed to `origin` |
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
- Fedora 44 VM `dwm-jangir-test-2`: default full-profile install (with Herdr
  skipped and third-party gaming repositories unapproved), upstream Slick
  Greeter, the `dwm-jangir` LightDM session, and the `Super+X` terminal
  keybinding. The full system-management suite passed: 682 tests in 835.492s.
- Installer non-TTY sudo preflight: the Fedora VM reproduces a non-interactive
  invocation without a pseudo-terminal exiting before build configuration or
  package changes, with the tested `ssh -tt` remediation message.

Not fully validated here:

- The host workspace lacks `PackageKitGlib 1.0` Python bindings, so its local
  full system-management run cannot initialize repository-read cases. That gap
  is closed by the passing Fedora 44 VM run above.
- `shfmt`, `qmllint`, and Xvfb are unavailable on the host. Run their dedicated
  formatter and QML/Xvfb checks before release when those tools are provisioned.

## Next Action

Review the final diff, run the unavailable Fedora validation where possible,
then push `dev` only with maintainer approval. Do not force-push or modify the
read-only upstream remote.
