# DWM-Jangir Fork Delta and Merge Map

## Purpose

This is the version-controlled record of every current, intentional difference
between `dwm-jangir` and `ChrisTitusTech/dwm-titus`. Read it for every upstream
sync, rebase, conflict, or review of fork-owned behavior.

`FORK.md` defines the policy. `PROJECT-STATE.md` records the current live
state. This file maps that policy to exact files and conflict decisions.

## Verified Baseline

Verified on 2026-08-29:

| Ref | Commit | Meaning |
| --- | --- | --- |
| `dev` / GitHub default branch | `3b1f179` | Public fork branch before the current local worktree changes. |
| Common ancestor | `46991ca` | Last upstream base incorporated by `dev`. |
| Live `upstream/main` | `97f1ed9` | Upstream has five commits not yet incorporated. |
| `origin/main` | `0bea4f6` | Legacy branch; do not use for new work. |

The committed fork-only history above the common ancestor is:

1. `1a68941 feat: add personal branding and display config`
2. `3b1f179 docs: restore project state after upstream sync`

## Current Maintained Delta

| ID | Paths | Intent | Conflict resolution | Verification |
| --- | --- | --- | --- | --- |
| D-001 | `config/quickshell/assets/rahuljangirwork.svg` | Ship Rahul Jangir branding. | Keep the fork SVG. | Confirm the SVG exists and the panel loads it. |
| D-002 | `config/quickshell/panel/LogoButton.qml` | Point the existing upstream logo control at the Rahul SVG. | Start with upstream's file; reapply only the asset reference using its current API. Do not keep unrelated fork edits. | Diff must show only the asset-reference change. |
| D-003 | `scripts/dwm-display-setup`, `tests/test-dwm-display-setup.sh`, `CHANGELOG.md` | Persist generic NVIDIA layouts through generated Xorg `MetaModes`, including output position and rotation. | Preserve the generic MetaModes generator and its test; never add Rahul-specific connector names, modes, or positions. | Run `tests/test-dwm-display-setup.sh`; verify a real X11 layout after reboot when NVIDIA is used. |
| D-004 | `scripts/dwm-session`, `scripts/.xinitrc`, `dwm.desktop`, `Makefile`, `lightdm/lightdm.conf`, `tests/test-lightdm-config.sh`, `CHANGELOG.md` | Give LightDM and `startx` one safe D-Bus-backed `dwm` session entry. | Preserve only the no-nested-bus guard and `exec dwm`; keep LightDM configuration aligned with the Fedora installer. | Run `sh -n scripts/dwm-session scripts/.xinitrc`, `tests/test-lightdm-config.sh`, and verify login/reboot. |
| D-005 | `AGENTS.md`, `FORK.md`, `FORK-DELTA.md`, `PROJECT-STATE.md`, `CONTRIBUTING.md`, `.gitignore` | Make the public fork and its agent workflow understandable and portable. | Keep the fork governance intent, but manually incorporate upstream documentation or ignore-rule improvements. | Read links and run `git diff --check`. |

Only D-001 through D-005 are approved. A new difference must be assigned a new
ID here before it becomes a permanent fork change.

## Display Configuration Boundary

Monitor configuration follows the upstream `dwm-display-setup` architecture.
It provides discovery, reversible preview, and persistent Xorg configuration;
it is run from the logged-in X11 session. D-003 extends the generated NVIDIA
configuration with generic MetaModes so saved position and rotation also apply
at the next LightDM/Xorg start. Do not add a LightDM `display-setup-script`, a
root script that reads user configuration, automatic profile selection,
`.bashrc` mutation, or static output layout to the repository.

The local LightDM workaround scripts and automatic profile code were removed
from the worktree on 2026-08-29 because they ran before the greeter as root and
could break the login session. They are not maintained deltas.

## Conflict Procedure

For each conflicted file during an upstream rebase or merge:

1. Identify its delta ID in the table above.
2. For an unlisted file, accept upstream unless the maintainer explicitly
   authorizes a new delta.
3. For D-002 through D-005, do not use `--ours` for the whole file. Take the
   current upstream structure and reapply the small documented fork behavior.
4. For D-001, retain the SVG but inspect it for compatibility with any upstream
   asset-pipeline changes.
5. Run the listed verification, review `git diff upstream/main -- <path>`, and
   update this file only if the intentional delta changed.

## Required End-of-Sync Checks

```sh
git diff --check
git diff --name-status upstream/main...HEAD
git diff upstream/main -- config/quickshell/panel/LogoButton.qml
scripts/run-tests make clean all
scripts/run-tests
```

Run focused shell, QML, installer, or X11 checks when the corresponding delta
changed. State any unavailable environment or tool in `PROJECT-STATE.md`.

## Historical Ledger

| Date | Decision | Status |
| --- | --- | --- |
| 2026-07-10 to 2026-08-27 | The fork accumulated panel, theme, terminal, wallpaper, tray, clock, and hardware-specific display changes. | Retired from the maintained delta; local `.agent/documentation/` remains historical reference only. |
| 2026-08-27 | Fork reset to upstream base `46991ca`, then branding and display behavior were reapplied in `1a68941`. | Superseded by the current generic display-profile policy. |
| 2026-08-29 | GitHub `dev` became the default public branch; fork policy was consolidated in version-controlled repository files. | Active. |
| 2026-08-29 | Removed the non-upstream LightDM display hook and automatic profile scripts; monitor persistence returns to upstream `dwm-display-setup`. | Active. |
| 2026-08-29 | Generated NVIDIA MetaModes and a shared D-Bus session launcher were validated; a real reboot confirmed DP-0 primary 2560x1440 and DVI-D-0 900x1440 rotated left. | Active. |

Historical material must never override this file, `FORK.md`, or
`PROJECT-STATE.md` during a merge.
