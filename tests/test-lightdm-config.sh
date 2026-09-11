#!/usr/bin/env bash
set -euo pipefail

repo=$(
	unset CDPATH
	cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fedora_stage="$work/fedora"
solar_stage="$work/solar"

make -C "$repo/lightdm" --no-print-directory \
	DESTDIR="$fedora_stage" \
	LIGHTDM_SEAT_SECTION='Seat:*' \
	LIGHTDM_GREETER_SESSION=slick-greeter \
	LIGHTDM_SESSION_WRAPPER= \
	LIGHTDM_LOGIND_CHECK=true \
	install >/dev/null
cat >"$work/fedora.expected" <<'CONF'
[LightDM]
logind-check-graphical=true

[Seat:*]
greeter-session=slick-greeter
user-session=dwm-jangir
CONF
cmp -s "$work/fedora.expected" "$fedora_stage/etc/lightdm/lightdm.conf"

grep -Fqx 'xft-dpi=96' "$fedora_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'activate-numlock=false' "$fedora_stage/etc/lightdm/slick-greeter.conf"
test ! -e "$fedora_stage/usr/libexec/dwm-jangir-slick-greeter"

make -C "$repo/lightdm" --no-print-directory \
	DESTDIR="$solar_stage" \
	LIGHTDM_THEME=solar \
	LIGHTDM_SEAT_SECTION='Seat:*' \
	LIGHTDM_SESSION_WRAPPER= \
	LIGHTDM_LOGIND_CHECK=true \
	install >/dev/null
grep -Fqx 'greeter-session=dwm-jangir-slick-greeter' \
	"$solar_stage/etc/lightdm/lightdm.conf"
grep -Fqx 'background=' "$solar_stage/etc/lightdm/slick-greeter.conf"
grep -Fqx 'theme-name=dwm-jangir-dark' "$solar_stage/etc/lightdm/slick-greeter.conf"
test -x "$solar_stage/usr/libexec/dwm-jangir-slick-greeter"
test -f "$solar_stage/usr/share/xgreeters/dwm-jangir-slick-greeter.desktop"
test -f "$solar_stage/usr/share/dwm-jangir/lightdm-assets/dwm.svg"
test -f "$solar_stage/usr/share/themes/dwm-jangir-dark/gtk-3.0/gtk.css"
test ! -e "$solar_stage/usr/share/dwm-jangir/lightdm-backgrounds"

printf 'LightDM config rendering: PASS\n'
