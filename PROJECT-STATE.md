---
title: DWM-Jangir Project State
type: live-project-state
project: dwm-jangir
status: active
last-verified: 2026-08-30
---

# DWM-Jangir Project State

This is the short, verified handoff record for agents and contributors. Read
`AGENTS.md` and `FORK.md` before acting; read `FORK-DELTA.md` before an
upstream sync or conflict. Keep historical decisions in Git, commit messages,
and dedicated documentation; do not use this file as a diary.

## Verified Git Snapshot

Verified on 2026-08-30 after successful upstream sync:

| Item | Verified value |
| --- | --- |
| Current branch | `sync/2026-08-30`, clean worktree |
| Public fork repository | `https://github.com/rahuljangirworks/dwm-jangir` |
| Read-only upstream repository | `https://github.com/ChrisTitusTech/dwm-titus` |
| Published `origin/dev` commit | `8cc8ed4` (`feat: complete dwm-titus → dwm-jangir runtime identity migration`) |
| Sync branch tip | `c60c139` (`feat: complete dwm-titus → dwm-jangir runtime identity migration` rebased) |
| Upstream sync base | `97f1ed9` (`feat(settings): persist panel widgets and compact Settings`) |
| Common ancestor (previous) | `46991ca` |
| Current upstream base | `97f1ed9` (fully synced) |
| GitHub default branch | `dev` at `8cc8ed4` (before sync) |
| Legacy branch | `origin/main` at `0bea4f6`; do not use |

The fork commits on `sync/2026-08-30` above `upstream/main` (97f1ed9):

1. `14f1f52 feat: add personal branding and display config`
2. `4579a77 docs: restore project state after upstream sync`
3. `db280a2 fix(display): persist NVIDIA layouts through Xorg`
4. `91db491 docs(fork): record upstream-safe display workflow`
5. `430c1f4 docs(fork): record display recovery verification`
6. `c60c139 feat: complete dwm-titus → dwm-jangir runtime identity migration`

## Verified Upstream Sync (2026-08-30)

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

The `sync/2026-08-30` branch is clean with all fork commits successfully rebased
onto latest upstream. The runtime-identity migration is complete: `dwm-jangir` is
the active name for all XDG, session, helper, Xorg, LightDM, release, and
source-asset paths. Legacy `dwm-titus` user directories have been removed from
the live system.

## Next Required Action

Review and merge the upstream sync:

1. Review the sync result:
   ```bash
   git log --oneline upstream/main..sync/2026-08-30
   git diff dev sync/2026-08-30
   ```

2. Merge sync branch to dev:
   ```bash
   git switch dev
   git merge --ff-only sync/2026-08-30
   ```

3. Update FORK-DELTA.md and PROJECT-STATE.md if needed

4. Push to origin (after Rahul's confirmation):
   ```bash
   git push origin dev
   ```

5. Clean up sync branch:
   ```bash
   git branch -d sync/2026-08-30
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
