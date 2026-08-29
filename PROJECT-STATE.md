---
title: DWM-Jangir Project State
type: live-project-state
project: dwm-jangir
status: active
last-verified: 2026-08-29
---

# DWM-Jangir Project State

This is the short, verified handoff record for agents and contributors. Read
`AGENTS.md` and `FORK.md` before acting; read `FORK-DELTA.md` before an
upstream sync or conflict. Keep historical decisions in Git, commit messages,
and dedicated documentation; do not use this file as a diary.

## Verified Git Snapshot

Verified on 2026-08-29 without modifying Git history or remote configuration:

| Item | Verified value |
| --- | --- |
| Current branch | `dev`, tracking `origin/dev`, with two local commits pending push |
| Published `origin/dev` commit | `3b1f179` (`synced-with-upstream-20260827`) |
| Latest implementation commit | `728a84b` (`fix(display): persist NVIDIA layouts through Xorg`) |
| Latest fork-record commit | `05a99b2` (`docs(fork): record upstream-safe display workflow`) |
| Locally fetched upstream base | `46991ca` |
| Live `upstream/main` | `97f1ed9` |
| Live comparison | `dev` has 4 fork commits; upstream has 5 newer commits; histories diverge at `46991ca` |
| GitHub default branch | `dev` at `3b1f179`; it matches `origin/dev` |
| Legacy branch | `origin/main` at `0bea4f6`; it is 98 commits behind `dev` |

The current fork commits above the common upstream base are:

1. `1a68941 feat: add personal branding and display config`
2. `3b1f179 docs: restore project state after upstream sync`
3. `728a84b fix(display): persist NVIDIA layouts through Xorg`
4. `05a99b2 docs(fork): record upstream-safe display workflow`

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

## Next Required Action

Ask Rahul before pushing the three local commits to `origin/dev`. Then install
ShellCheck and shfmt before the next upstream sync and run the managed shell and
format checks. The supported monitor path is `dwm-display-setup` from a
logged-in X11 session, with reversible preview and persistent Xorg
configuration. Do not restore a LightDM display hook, `.bashrc` profile
selection, static monitor layout, or emergency repair script.

After the commits are pushed and the worktree is clean:

1. Fetch upstream and create a dated `sync/YYYY-MM-DD` branch.
2. Rebase the integration branch onto the exact `upstream/main` SHA.
3. Preserve only the allowed branding and portable governance deltas.
4. Run the required validation.
5. Update this record with the resulting SHA, validation, and one next action.

## Public Branch Policy

`dev` is the tested public branch, active integration branch, and current
GitHub default branch. `main` is a legacy compatibility branch and must not be
used for new work while it remains behind `dev`. The current CI configuration
runs direct-push validation only for `main`; update it to include `dev` before
relying on direct pushes as a quality gate. Do not merge, reset, rename, delete,
or push branches without the maintainer's explicit approval.
