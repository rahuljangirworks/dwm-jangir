#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT_DIR/scripts/dwm-display-setup"
BASH_BIN="${BASH:-/usr/bin/bash}"

if ! command -v python3 >/dev/null 2>&1; then
	printf '%s\n' 'test-dwm-display-wizard: SKIP (python3 PTY harness is unavailable)'
	exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/bin" "$work/etc/X11/xorg.conf.d"

cat >"$work/query" <<'EOF'
Screen 0: minimum 8 x 8, current 3360 x 1920, maximum 32767 x 32767
HDMI-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis)
   1920x1080     60.00*+
DP-1 connected 1440x2560+1920+0 left (normal left inverted right x axis y axis)
   2560x1440     60.00*+
EOF

cat >"$work/verbose" <<'EOF'
HDMI-1 connected primary 1920x1080+0+0 (0x46) normal (normal left inverted right x axis y axis)
  1920x1080 (0x47) 148.500MHz +HSync +VSync *current +preferred
        h: width  1920 start 2008 end 2052 total 2200 skew    0 clock  67.50KHz
        v: height 1080 start 1084 end 1089 total 1125           clock  60.00Hz
DP-1 connected 1440x2560+1920+0 (0x50) left (normal left inverted right x axis y axis)
  2560x1440 (0x51) 241.500MHz +HSync -VSync *current +preferred
        h: width  2560 start 2608 end 2640 total 2720 skew    0 clock  88.79KHz
        v: height 1440 start 1443 end 1448 total 1481           clock  60.00Hz
EOF

cat >"$work/bin/xrandr" <<'EOF'
#!/bin/sh
case ${1:-} in
--query | --current) cat "$TEST_QUERY" ;;
--verbose) cat "$TEST_VERBOSE" ;;
--prop) cat "$TEST_PROPERTIES" ;;
*) exit 0 ;;
esac
EOF
chmod +x "$work/bin/xrandr"
printf '%s\n' 'HDMI-1 connected' 'DP-1 connected' >"$work/properties"

run_wizard() {
	local input=$1 config=$2 output=$3
	env DISPLAY=:77 DWM_DISPLAY_NO_SUDO=1 DWM_KERNEL_DRIVER=modesetting \
		DWM_XORG_DRIVER=modesetting DWM_XORG_MAIN_CONFIG="$work/etc/X11/xorg.conf" \
		PATH="$work/bin:/usr/bin:/bin" TEST_QUERY="$work/query" \
		TEST_VERBOSE="$work/verbose" TEST_PROPERTIES="$work/properties" \
		python3 - "$input" "$output" "$BASH_BIN" "$HELPER" "$config" <<'PY'
import errno
import os
import pty
import select
import subprocess
import sys

input_path, output_path, bash, helper, config = sys.argv[1:]
master, slave = pty.openpty()
with open(input_path, "rb") as source:
    process = subprocess.Popen(
        [bash, helper, "wizard", "--no-preview", "--yes", "--config", config],
        stdin=slave,
        stdout=slave,
        stderr=slave,
        close_fds=True,
    )
    os.close(slave)
    os.write(master, source.read())

chunks = []
while True:
    readable, _, _ = select.select([master], [], [], 0.1)
    if master in readable:
        try:
            data = os.read(master, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b""
        if data:
            chunks.append(data)
        elif process.poll() is not None:
            break
    if process.poll() is not None and not readable:
        break

os.close(master)
transcript = b"".join(chunks)
with open(output_path, "wb") as target:
    target.write(transcript)
if process.wait() != 0:
    sys.stderr.buffer.write(transcript)
    raise SystemExit(process.returncode)
PY
}

# Automatic is the default. DP-1 is selected as primary, so it must start at
# 0x0 and its rotated effective width (1440) determines HDMI-1's position.
printf '\n\n\n\n\n\nleft\n2\n' >"$work/automatic-input"
run_wizard "$work/automatic-input" "$work/automatic.conf" "$work/automatic-output"
grep -Fq 'Calculated display layout:' "$work/automatic-output"
grep -Fq 'DP-1 --mode 2560x1440 --rate 60.00 --pos 0x0 --rotate left --primary' "$work/automatic-output"
grep -Fq 'HDMI-1 --mode 1920x1080 --rate 60.00 --pos 1440x0 --rotate normal' "$work/automatic-output"

# Manual mode continues to accept explicit X/Y positions and retains the chosen
# primary output rather than reordering the profile.
printf 'n\n\n\n\n100\n200\n\n\nleft\n300\n400\n1\n' >"$work/manual-input"
run_wizard "$work/manual-input" "$work/manual.conf" "$work/manual-output"
grep -Fq 'HDMI-1 --mode 1920x1080 --rate 60.00 --pos 100x200 --rotate normal --primary' "$work/manual-output"
grep -Fq 'DP-1 --mode 2560x1440 --rate 60.00 --pos 300x400 --rotate left' "$work/manual-output"

printf '%s\n' 'test-dwm-display-wizard: ok'
