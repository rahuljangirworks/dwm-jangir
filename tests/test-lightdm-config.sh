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
user-session=dwm-jangir
CONF
cmp -s "$work/fedora.expected" "$fedora_stage/etc/lightdm/lightdm.conf"
cmp -s "$repo/lightdm/lightdm.conf" "$fedora_stage/etc/lightdm/lightdm.conf"

grep -Fqx 'xft-dpi=96' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'activate-numlock=false' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'show-clock=false' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'show-quit=true' "$fedora_stage/etc/lightdm/slick-greeter.conf"
test -x "$fedora_stage/usr/libexec/dwm-jangir-slick-greeter"
test -f "$fedora_stage/usr/share/xgreeters/dwm-jangir-slick-greeter.desktop"
test -f "$fedora_stage/usr/share/themes/dwm-jangir-dark/gtk-3.0/gtk.css"
test -f "$fedora_stage/usr/share/dwm-jangir/lightdm-backgrounds/SOURCES.md"
test "$(find "$fedora_stage/usr/share/dwm-jangir/lightdm-backgrounds" -name '*.webp' | wc -l)" -eq 9
! grep -Fq 'display-setup-script=' "$fedora_stage/etc/lightdm/lightdm.conf"
bash -n "$repo/lightdm/dwm-jangir-slick-greeter"

printf 'LightDM config rendering: PASS\n'
