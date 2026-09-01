---
title: DWM-Jangir Project State
type: live-project-state
project: dwm-jangir
status: active
last-verified: 2026-09-01
---

# DWM-Jangir Project State

This is the short, verified handoff record for agents and contributors. Read
`AGENTS.md` and `FORK.md` before acting; read `FORK-DELTA.md` before an
upstream sync or conflict. Keep historical decisions in Git, commit messages,
and dedicated documentation; do not use this file as a diary.

## Verified Git Snapshot

Verified on 2026-09-01 after rebasing the current fork work onto the latest
upstream and merging the validated result into `dev`:

| Item | Verified value |
| --- | --- |
| Current branch | `dev`, clean worktree |
| Public fork repository | `https://github.com/rahuljangirworks/dwm-jangir` |
| Read-only upstream repository | `https://github.com/ChrisTitusTech/dwm-titus` |
| Integration branch before this sync | `dev` at `91fdc55` |
| Merged sync | `4153460` (`merge: sync upstream 2026-09-01`) |
| Previous upstream base | `97f1ed9` |
| Current upstream base | `70e6e43` (`Prefer desktop ChatGPT for legacy web hotkeys (#197)`) |
| GitHub default branch | `dev` (not changed by this validation) |
| Legacy branch | `origin/main` at `0bea4f6`; do not use |

The fork commits on `sync/2026-08-30` above `upstream/main` (97f1ed9):

1. `14f1f52 feat: add personal branding and display config`
2. `4579a77 docs: restore project state after upstream sync`
3. `db280a2 fix(display): persist NVIDIA layouts through Xorg`
4. `91db491 docs(fork): record upstream-safe display workflow`
5. `430c1f4 docs(fork): record display recovery verification`
6. `c60c139 feat: complete dwm-titus → dwm-jangir runtime identity migration`

## Verified Upstream Sync (2026-09-01)

Rebased the 21 current fork commits onto `upstream/main` at `70e6e43` on
`sync/2026-09-01`, then merged that validated result into `dev` as `4153460`.
The result retained upstream's Astro documentation migration,
accessibility/settings work, and web-app compatibility changes while preserving
the documented fork identity, display, session, branding, and LightDM deltas.

Conflicts resolved from the current upstream structure:

- Makefile check targets retained the upstream additions and fork session/display
  helpers.
- The docs workflow now uses upstream Astro while retaining the fork Pages
  deployment identity; obsolete mdBook files were removed.
- Runtime-identity docs and tests now use Astro's `docs/src/content/` layout.
- Changelog entries retain both upstream and fork history.

Validation passed:

- `scripts/run-tests make clean all`, `make check-shell`, `git diff --check`.
- Focused LightDM, runtime-identity, display, install-preservation, and web-app
  launcher tests.
- VM staged build and system installation at `1920x1080`; `/usr/local/bin/dwm`
  builds as `dwm-0.7.0`, its session launcher passes `sh -n`, and only
  `dwm-jangir.desktop` remains visible to LightDM.
- LightDM restarted successfully with no new warning/error entries; the
  installed branded greeter rendered correctly and averaged about 1% CPU over
  15 seconds (about 54 MiB RSS).

The host's complete test runner is blocked only at `make check-format` because
`shfmt` is not installed. Do not treat that environment gap as a code failure;
run the full formatter check on a provisioned Fedora development host before a
release.

## Historical Upstream Sync (2026-08-30)

Successfully rebased all 6 fork commits onto `upstream/main` (97f1ed9) on branch `sync/2026-08-30`.

**Conflicts resolved:**
- Makefile: D-007 runtime identity preserved (all `dwm-jangir` paths)
- CHANGELOG.md: Merged upstream + fork additions
- README.md: D-002 branding preserved (dwm-jangir logo)

**Validation passed:**
- `bash -n install.sh scripts/dwm-display-setup` — clean
- `git diff --check` — no whitespace errors
- Runtime identity: All active paths use `dwm-jangir`
- Legacy `dwm-titus` only in migration logic (correct per D-007)

All seven maintained deltas (D-001 through D-007) preserved correctly.

## Verified Display Recovery

The current local commits remove the old static monitor command, add one
D-Bus-backed `dwm-session` entry for LightDM and `startx`, and generate generic
NVIDIA MetaModes for persistent mode, position, and rotation. The unsafe local
LightDM root-hook scripts were removed. `.agent` remains a local, ignored link.

`bash -n`/`sh -n` passed for the relevant shell files on 2026-08-29.
`tests/test-dwm-display-setup.sh` and `tests/test-lightdm-config.sh` passed.
The generated LightDM configuration contains no `display-setup-script`.

After the fixed LightDM configuration was deployed and the machine rebooted,
the user verified this X11 layout:

- `DP-0` primary at `2560x1440+0+0`.
- `DVI-D-0` at `900x1440+2560+0`, rotated left.
- Combined X11 desktop: `3460x1440`.

The managed shell check could not run because `shellcheck` is not installed;
`shfmt` and the full suite remain unrun.

## Current Local Worktree

The `dev` branch contains all current fork commits rebased onto `upstream/main`
at `70e6e43`. The runtime-identity migration is complete:
`dwm-jangir` is the active name for all XDG, session, helper, Xorg, LightDM,
release, and source-asset paths.

## Next Required Action

The sync is merged locally and remains unpushed. Before publishing, review the
merged result and then push only with maintainer approval:

1. Review the merged result:
   ```bash
   git log --oneline upstream/main..dev
   git diff upstream/main...dev
   ```

2. Push to origin (after Rahul's confirmation):
   ```bash
   git push origin dev
   ```

3. Clean up the sync branch after the merge is safely published:
   ```bash
   git branch -d sync/2026-09-01
   ```

Install ShellCheck and shfmt before the next upstream sync to enable managed
shell and format checks. The supported monitor path is `dwm-display-setup` from
a logged-in X11 session, with reversible preview and persistent Xorg
configuration.

## Public Branch Policy

`dev` is the tested public branch, active integration branch, and current
GitHub default branch. `main` is a legacy compatibility branch and must not be
used for new work while it remains behind `dev`. The current CI configuration
runs direct-push validation only for `main`; update it to include `dev` before
relying on direct pushes as a quality gate. Do not merge, reset, rename, delete,
or push branches without the maintainer's explicit approval.
