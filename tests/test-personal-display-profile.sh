#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/scripts/dwm-personal-display-profile"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin"
cat >"$work/bin/xrandr" <<'EOF'
#!/bin/sh
case ${MOCK_XRANDR_LAYOUT:-matching} in
matching)
	cat <<'OUTPUT'
Screen 0: minimum 8 x 8, current 3460 x 1440, maximum 32767 x 32767
DVI-D-0 connected 900x1440+2560+0 left (normal left inverted right x axis y axis)
DP-0 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis)
OUTPUT
	;;
mismatch)
	cat <<'OUTPUT'
Screen 0: minimum 8 x 8, current 2560 x 1440, maximum 32767 x 32767
DVI-D-0 disconnected (normal left inverted right x axis y axis)
DP-0 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis)
OUTPUT
	;;
*)
	exit 2
	;;
esac
EOF
chmod +x "$work/bin/xrandr"

XDG_CONFIG_HOME="$work/config" "$HELPER" prepare dell-5820 >"$work/profile-path"
profile=$(<"$work/profile-path")
expected="$ROOT_DIR/profiles/dell-5820.conf"

cmp -s "$expected" "$profile"
[[ $(stat -c %a "$profile") == 600 ]]

env PATH="$work/bin:$PATH" DISPLAY=:99 "$HELPER" validate dell-5820 "$profile" \
	>"$work/validate-output"
grep -Fq 'Dell 5820 output check passed' "$work/validate-output"

if env PATH="$work/bin:$PATH" DISPLAY=:99 MOCK_XRANDR_LAYOUT=mismatch \
	"$HELPER" validate dell-5820 "$profile" >"$work/mismatch-output" 2>&1; then
	printf '%s\n' 'mismatched hardware was accepted' >&2
	exit 1
fi
grep -Fq 'profile requires connected output DVI-D-0' "$work/mismatch-output"
grep -Fq 'dwm-display-setup' "$work/mismatch-output"

printf '%s\n' '# user-owned variation' >"$profile"
if XDG_CONFIG_HOME="$work/config" "$HELPER" prepare dell-5820 \
	>"$work/preserve-output" 2>&1; then
	printf '%s\n' 'different existing user profile was replaced' >&2
	exit 1
fi
grep -Fq '# user-owned variation' "$profile"
grep -Fq 'was preserved' "$work/preserve-output"

printf '%s\n' 'test-personal-display-profile: ok'
