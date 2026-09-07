#!/usr/bin/env bash
set -euo pipefail

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fedora_stage="$work/fedora"

make -C "$repo/lightdm" --no-print-directory \
	DESTDIR="$fedora_stage" \
	LIGHTDM_SEAT_SECTION='Seat:*' \
	LIGHTDM_GREETER_SESSION=dwm-jangir-slick-greeter \
	LIGHTDM_SESSION_WRAPPER= \
	LIGHTDM_LOGIND_CHECK=true \
	install >/dev/null
cat >"$work/fedora.expected" <<'CONF'
[LightDM]
logind-check-graphical=true

[Seat:*]
greeter-session=dwm-jangir-slick-greeter
greeter-session=slick-greeter
user-session=dwm-jangir
CONF
cmp -s "$work/fedora.expected" "$fedora_stage/etc/lightdm/lightdm.conf"
cmp -s "$repo/lightdm/lightdm.conf" "$fedora_stage/etc/lightdm/lightdm.conf"

grep -Fqx 'xft-dpi=96' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'activate-numlock=false' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'show-clock=false' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'clock-format=%I:%M %p' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'show-quit=true' "$fedora_stage/etc/lightdm/slick-greeter.conf"
test -x "$fedora_stage/usr/libexec/dwm-jangir-slick-greeter"
test -f "$fedora_stage/usr/share/xgreeters/dwm-jangir-slick-greeter.desktop"
test -f "$fedora_stage/usr/share/themes/dwm-jangir-dark/gtk-3.0/gtk.css"
test -f "$fedora_stage/usr/share/dwm-jangir/lightdm-backgrounds/SOURCES.md"
test -f "$fedora_stage/usr/share/dwm-jangir/lightdm-assets/dwm.svg"
test "$(find "$fedora_stage/usr/share/dwm-jangir/lightdm-backgrounds" -name '*.webp' | wc -l)" -eq 9
grep -Fq 'Signing in…' "$repo/lightdm/rpm/patches/0001-dwm-jangir-greeter-ui.patch"
grep -Fq 'Desktop session' "$repo/lightdm/rpm/patches/0001-dwm-jangir-greeter-ui.patch"
grep -Fq 'pending_error_message = text' "$repo/lightdm/rpm/patches/0001-dwm-jangir-greeter-ui.patch"
grep -Fq 'Shut down?' "$repo/lightdm/rpm/patches/0001-dwm-jangir-greeter-ui.patch"
grep -Fq 'Restart?' "$repo/lightdm/rpm/patches/0001-dwm-jangir-greeter-ui.patch"
grep -Fq 'https://wttr.in/' "$repo/lightdm/rpm/patches/0001-dwm-jangir-greeter-ui.patch"
grep -Eq '^Requires:[[:space:]]+curl' "$repo/lightdm/rpm/dwm-jangir-slick-greeter.spec"
if grep -Fq 'display-setup-script=' "$fedora_stage/etc/lightdm/lightdm.conf"; then
	printf '%s\n' 'LightDM display hooks are not supported.' >&2
	exit 1
fi
bash -n "$repo/lightdm/dwm-jangir-slick-greeter"

printf 'LightDM config rendering: PASS\n'
