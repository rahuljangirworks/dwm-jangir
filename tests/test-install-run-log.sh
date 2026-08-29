#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat >"$work/unsupported-os-release" <<'EOF'
ID=example
PRETTY_NAME="Unsupported Linux"
EOF
cat >"$work/fedora-os-release" <<'EOF'
ID=fedora
PRETTY_NAME="Fedora Linux 44"
EOF

state_home="$work/state"
home="$work/home"
mkdir -p "$home"

set +e
DWM_TEST_MODE=1 DWM_INSTALL_LOG=1 DWM_OS_RELEASE="$work/unsupported-os-release" \
	HOME="$home" XDG_STATE_HOME="$state_home" "$ROOT_DIR/install.sh" \
	--non-interactive --profile core >"$work/unsupported-output" 2>&1
status=$?
set -e
[[ $status == 1 ]]

log="$state_home/dwm-jangir/install-last.log"
test -f "$log"
[[ $(stat -c %a "$log") == 600 ]]
grep -Fq 'Unsupported distribution: Unsupported Linux' "$log"
grep -Fq 'Installer result: failed (exit status 1)' "$log"
grep -Fq "Installer log saved: $log" "$work/unsupported-output"
[[ $(find "$state_home/dwm-jangir" -maxdepth 1 -type f | wc -l) == 1 ]]

printf '%s\n' 'previous installer record' >"$log"
DWM_TEST_MODE=1 DWM_INSTALL_LOG=1 DWM_OS_RELEASE="$work/fedora-os-release" \
	HOME="$home" XDG_STATE_HOME="$state_home" "$ROOT_DIR/install.sh" \
	--dry-run --non-interactive --profile core >"$work/dry-run-output"
grep -Fq 'Preflight inspection (read-only):' "$work/dry-run-output"
grep -Fq 'previous installer record' "$log"

printf '%s\n' 'test-install-run-log: ok'
