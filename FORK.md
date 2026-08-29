# DWM-Jangir Fork Contract

## Purpose

This is Rahul Jangir's public Fedora X11 desktop fork of
`ChrisTitusTech/dwm-titus`. The fork intentionally keeps a very small,
maintainable delta from upstream. It is not an independent rewrite of the
desktop.

## Authority and Reading Order

Every agent and contributor must read these files before changing the project:

1. `AGENTS.md` for engineering, safety, and validation rules.
2. This file for fork scope, branch roles, and upstream handling.
3. `PROJECT-STATE.md` for verified current Git state and the next action.
4. `FORK-DELTA.md` before an upstream sync, conflict resolution, or review of
   fork-owned behavior.

For a task that changes an upstream product feature, `SPEC.md`, `ROADMAP.md`,
and `TASKS.md` also apply. They do not authorize new roadmap work in this fork
by themselves. An agent must receive explicit maintainer approval before
starting work outside the allowed fork delta below.

When instructions conflict, preserve safety rules in `AGENTS.md`, then follow
this fork contract for fork-specific decisions. `PROJECT-STATE.md` records
facts; it never overrides a durable policy.

## Allowed Permanent Delta and Display Boundary

Keep only changes that fit one of these categories:

| Area | Allowed change | Boundary |
| --- | --- | --- |
| Branding | Rahul Jangir logo and the minimal reference required to display it. | Do not change unrelated panel styling or assets. |
| Display persistence | Generic fixes implemented through the upstream display setup and persistent Xorg configuration path. | No LightDM display hook, shell-profile mutation, static output layout, or repository-owned machine profile. |
| Session startup | Minimal, generic D-Bus session guard shared by LightDM and `startx`. | Do not add desktop policy, display setup, or user-specific environment to the wrapper. |

Use `dwm-display-setup` from an X11 session for reversible preview and
persistent Xorg configuration. Do not add a LightDM `display-setup-script`,
login hook, shell-profile mutation, static monitor command, or
repository-owned layout.

Everything else should follow upstream. If a requested change does not clearly
fit this table, stop and ask the maintainer whether it is a permanent fork
delta or an upstream contribution.

## Branch and Remote Policy

| Ref | Role | Rule |
| --- | --- | --- |
| `upstream/main` | Read-only ChrisTitusTech source. | Fetch only; never push. |
| `dev` | Tested public branch, active integration branch, and current GitHub default branch. | Merge only validated work. |
| `main` | Legacy branch retained for compatibility. | Do not start new work here; it is currently behind `dev`. |
| `feature/*` | One focused change. | Rebase or merge only after validation. |
| `sync/YYYY-MM-DD` | One upstream synchronization. | Delete only after the validated sync is safely merged. |

Configure the upstream remote with no usable push URL before the next sync:

```sh
git remote set-url --push upstream DISABLED
```

Do not force-push, reset, delete branches, merge into `dev`, alter GitHub
repository settings, or push any branch unless the maintainer explicitly asks.

## Upstream Synchronization Procedure

1. Read `PROJECT-STATE.md` and inspect `git status --short --branch`.
2. Do not synchronize while uncommitted changes are ambiguous. Split them into
   focused, reviewed commits or preserve them on a dedicated work branch.
3. Run `git fetch upstream --prune` and record the exact upstream SHA.
4. Create `sync/YYYY-MM-DD` from the current integration branch, then rebase it
   onto `upstream/main`.
5. Resolve conflicts by retaining only the allowed permanent delta. Prefer
   upstream for every other file or behavior.
6. Resolve each conflict through `FORK-DELTA.md`, then run the validation
   required by `AGENTS.md` and record both passes and gaps.
7. Update `PROJECT-STATE.md` with verified facts only.
8. Ask the maintainer before merging the validated result into `dev` or
   pushing it to GitHub.

## Agent Change Discipline

- Start every task by reading the three authority files and checking Git state.
- Treat files outside this repository, including a local `.agent` link, as
  optional notes rather than portable project authority.
- Do not commit local repair, emergency-login, backup, generated, or hardware
  files unless they have been deliberately converted into a documented,
  tested, generic project feature.
- Keep a change small enough to describe in one pull request and one commit
  series. Record validation and remaining risks in the commit or pull request.
- Update `PROJECT-STATE.md` only after a meaningful verification, sync, merge,
  or change in the next action. Remove superseded claims instead of piling up
  historical notes into the live state file.

## Public-Fork Checklist

Before presenting this as an independently maintained open-source project,
the maintainer should enable Issues, protect `dev`, ensure CI runs on direct
pushes to `dev`, update `CODEOWNERS` and security/support contacts, and decide
whether README, releases, and docs point to this fork or explicitly describe it
as a personal upstream-compatible fork.
