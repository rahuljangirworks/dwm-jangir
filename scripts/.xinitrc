#!/bin/bash

# .xinitrc — only used when starting dwm via startx (not SDDM)
# All setup (DPMS, dbus env, services) is handled by autostart.sh

# Monitor configuration
xrandr --output DP-0 --primary --mode 2560x1440 --rate 59.95 --pos 0x0 --rotate normal --output DVI-D-0 --mode 1440x900 --rate 59.89 --pos 2560x0 --rotate left

dbus-run-session -- sh -c 'exec dwm'
