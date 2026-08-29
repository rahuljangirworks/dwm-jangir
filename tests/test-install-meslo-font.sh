#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

helpers=$(awk '
	/^meslo_nerd_font_installed\(\)/ { include = 1 }
	/^install_nordic_gtk_theme\(\)/ { exit }
	include { print }
' "$repo_dir/install.sh")
[[ -n $helpers ]]

ok() { printf '%s\n' "$*" >>"$work/messages"; }
info() { :; }
err() { :; }
eval "$helpers"

mkdir -p "$work/bin" "$work/home"
cat >"$work/bin/fc-match" <<'EOF'
#!/bin/sh
printf '%s\n' 'MesloLGS Nerd Font Mono'
EOF
cat >"$work/bin/curl" <<'EOF'
#!/bin/sh
printf '%s\n' called >>"${DWM_TEST_CURL_LOG:?}"
exit 1
EOF
chmod 755 "$work/bin/fc-match" "$work/bin/curl"

PATH="$work/bin:$PATH" HOME="$work/home" DWM_TEST_CURL_LOG="$work/curl.log" \
	install_meslo_nerd_font
grep -Fqx 'MesloLGS Nerd Font is already installed.' "$work/messages"
[[ ! -e $work/curl.log ]]

printf '%s\n' 'test-install-meslo-font: ok'
