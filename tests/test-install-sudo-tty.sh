#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cat >"$work/fedora-os-release" <<'EOF'
ID=fedora
PRETTY_NAME="Fedora Linux 44"
EOF
mkdir -p "$work/bin" "$work/home"

cat >"$work/bin/dnf" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$work/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${DWM_TEST_SUDO_LOG:?}"
exit 1
EOF
chmod 755 "$work/bin/dnf" "$work/bin/sudo"

set +e
DWM_TEST_MODE=1 DWM_OS_RELEASE="$work/fedora-os-release" \
	DWM_TEST_SUDO_LOG="$work/sudo.log" HOME="$work/home" \
	PATH="$work/bin:$PATH" "$repo/install.sh" \
	--non-interactive --profile core </dev/null >"$work/output" 2>&1
status=$?
set -e

if [[ $status -ne 1 ]]; then
	printf 'Non-TTY installer exited with %s instead of 1.\n' "$status" >&2
	exit 1
fi
grep -Fq 'The installer needs sudo access, but no interactive terminal is available.' \
	"$work/output"
grep -Fq 'allocate one with: ssh -tt user@host' "$work/output"
grep -Fqx -- '-n -v' "$work/sudo.log"
if grep -Eq 'Created .*config\.h|Preserving existing .*config\.h' "$work/output"; then
	printf 'Installer reached build configuration before validating sudo access.\n' >&2
	exit 1
fi

printf '%s\n' 'test-install-sudo-tty: ok'
