---
title: DWM-Jangir Project State
type: project-state
project: dwm-jangir
status: active
work-claim: none
last-updated: 2026-08-27
---

# DWM-Jangir Project State

## Overview

Personal fork of ChrisTitusTech/dwm-titus window manager.

- **Base**: ChrisTitusTech/dwm-titus
- **Repository**: https://github.com/rahuljangirworks/dwm-jangir
- **Branch**: dev
- **Policy**: 99% upstream + logo + display config

## Fork Policy

This fork maintains **minimal delta** from upstream:

### Always Keep (2 Changes)
1. **Logo**: Personal branding (rahuljangirwork.svg)
2. **Display Config**: Dual monitor setup (DP-0 + DVI-D-0)

### Always Match Upstream
- Panel styling
- Themes
- Terminal configs
- Application hotkeys
- All other configurations

**Golden Rule**: When in doubt, choose upstream.

## Current Status

- **Synced with upstream**: ⚠️ NO (pending sync)
- **Ahead**: 23 commits + uncommitted changes
- **Behind**: 9 commits
- **Next Action**: Full upstream sync (keep only logo + display)

## Hardware Setup

### Display Configuration
```bash
# Primary: DP-0
Resolution: 2560x1440
Refresh: 60Hz
Position: 0,0
Rotation: Normal

# Secondary: DVI-D-0
Resolution: 1440x900
Refresh: 59.89Hz
Position: 2560,0
Rotation: Left (portrait)
```

## Maintenance Schedule

- **Upstream sync**: Monthly (check for new commits)
- **Testing**: After each sync
- **Documentation**: Keep agent docs updated

## Agent Instructions

### For Merge Conflicts

**Rule 1: Logo & Display → OURS**
```bash
git checkout --ours config/quickshell/assets/rahuljangirwork.svg
git checkout --ours config/quickshell/panel/LogoButton.qml  # logo line only
git checkout --ours scripts/autostart.sh  # xrandr line only
git checkout --ours scripts/.xinitrc  # xrandr line only
```

**Rule 2: Everything Else → THEIRS**
```bash
git checkout --theirs <any-other-file>
```

### For New Upstream Features

Always adopt upstream's version. Test after sync.

### Documentation Location

All fork documentation:
- `~/.work/04-personal-projacts/dwm-jangir/_agent/documentation/`

Key files:
- `CUSTOMIZATION-INVENTORY.md` - What we had
- `AGENT-MERGE-GUIDE.md` - How to merge
- `RECREATION-GUIDE.md` - How to recreate features
- `SYNC-EXECUTION-PLAN.md` - Sync procedure

## Recent Activity

**2026-08-27**:
- Documented all customizations before sync
- Created agent merge guide
- Ready to execute upstream sync
- Updated policy: Keep only logo + display config

**Previous**: 
- Added flat panel styling (will remove)
- Added modern clock (will remove)
- Fixed Flameshot tray (will remove)
- Added Rajasthani theme (will remove)

## Next Steps

1. Execute upstream sync per SYNC-EXECUTION-PLAN.md
2. Keep only: logo + display config
3. Test build and installation
4. Update this file after sync
5. Monitor for issues

## Testing Checklist

After any change:
- [ ] `make clean && make` succeeds
- [ ] `./install.sh` succeeds
- [ ] Quickshell starts without errors
- [ ] Logo displays correctly
- [ ] Both monitors configured properly
- [ ] Panel functions work
- [ ] No regressions

## Related Files

- Brain: `~/.work/04-personal-projacts/dwm-jangir/`
- Runnable: `~/work/personal-projacts/dwm-jangir/`
- Config: `~/work/personal-projacts/dwm-jangir/config/`
- Scripts: `~/work/personal-projacts/dwm-jangir/scripts/`

---

**Project Owner**: Rahul Jangir
**Agent Contact**: Personal Buddy / Project Agent
**Escalation**: Ask user before destructive changes
