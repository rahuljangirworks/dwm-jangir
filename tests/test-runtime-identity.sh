#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
	printf 'test-runtime-identity: %s\n' "$*" >&2
	exit 1
}

grep -Fqx 'Name=dwm-jangir' "$repo_dir/dwm-jangir.desktop"
grep -Fqx 'Comment=Dynamic window manager (dwm-jangir)' "$repo_dir/dwm-jangir.desktop"
grep -Fq 'XSESSIONSDIR}/dwm-jangir.desktop' "$repo_dir/Makefile"
grep -Fq "DATA_DIR  := \${XDG_DATA_HOME}/dwm-jangir" "$repo_dir/Makefile"
grep -Fq "PRIVILEGED_HELPER_DIR = \${PREFIX}/libexec/dwm-jangir" "$repo_dir/Makefile"
grep -Fq 'static const char dwmdir[] = "dwm-jangir";' "$repo_dir/dwm.c"
grep -Fq '90-dwm-jangir-display.conf' "$repo_dir/scripts/dwm-display-setup"
grep -Fq "legacy \`dwm-titus\` XDG configuration, data, and state directories" "$repo_dir/docs/src/install.md"

# Execute only the user-owned migration helper definitions. This covers the
# two important safety cases without invoking the installer or sudo.
migration_helpers=$(awk '
	/^migrate_user_runtime_directory\(\)/ { include = 1 }
	/^migrate_managed_xorg_identity\(\)/ { exit }
	include { print }
' "$repo_dir/install.sh")
[[ -n $migration_helpers ]] || fail 'could not extract user migration helpers'

ok() { :; }
warn() { :; }
eval "$migration_helpers"

export HOME="$work/home"
mkdir -p "$HOME"
legacy="$HOME/.config/dwm-titus"
current="$HOME/.config/dwm-jangir"
mkdir -p "$legacy"
printf '%s\n' legacy >"$legacy/hotkeys.toml"
migrate_user_runtime_directory "$legacy" "$current"
[[ ! -e $legacy ]] || fail 'unambiguous legacy directory was not moved'
[[ $(<"$current/hotkeys.toml") == legacy ]] || fail 'migrated settings changed'

# When both directories contain conflicting files, retain the legacy copy and
# do not overwrite the existing current setting.
mkdir -p "$legacy"
printf '%s\n' legacy-value >"$legacy/themes.toml"
printf '%s\n' current-value >"$current/themes.toml"
printf '%s\n' legacy-only >"$legacy/window-rules.toml"
migrate_user_runtime_directory "$legacy" "$current"
[[ -d $legacy ]] || fail 'divergent legacy settings were removed'
[[ $(<"$current/themes.toml") == current-value ]] || fail 'current setting was overwritten'
[[ $(<"$legacy/themes.toml") == legacy-value ]] || fail 'legacy setting changed'
[[ $(<"$current/window-rules.toml") == legacy-only ]] || fail 'missing legacy setting was not copied'

# Managed checkout data can be removed only after the replacement has its
# expected source directories. State is removable when it is fully subsumed by
# the new directory, even if the new installer log is additional.
USER_DATA_HOME="$HOME/.local/share"
USER_STATE_HOME="$HOME/.local/state"
export LEGACY_RUNTIME_ID=dwm-titus
export RUNTIME_ID=dwm-jangir
mkdir -p "$USER_DATA_HOME/dwm-titus/config" "$USER_DATA_HOME/dwm-titus/scripts"
mkdir -p "$USER_DATA_HOME/dwm-jangir/config" "$USER_DATA_HOME/dwm-jangir/scripts"
mkdir -p "$USER_STATE_HOME/dwm-titus/appearance" "$USER_STATE_HOME/dwm-jangir/appearance"
printf '%s\n' preserved >"$USER_STATE_HOME/dwm-titus/appearance/state"
cp "$USER_STATE_HOME/dwm-titus/appearance/state" "$USER_STATE_HOME/dwm-jangir/appearance/state"
printf '%s\n' current-log >"$USER_STATE_HOME/dwm-jangir/install-last.log"
cleanup_legacy_user_runtime
[[ ! -e $USER_DATA_HOME/dwm-titus ]] || fail 'stale managed data was retained'
[[ ! -e $USER_STATE_HOME/dwm-titus ]] || fail 'subsumed legacy state was retained'

printf '%s\n' 'test-runtime-identity: ok'
