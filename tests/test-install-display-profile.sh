#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

common=(--dry-run --non-interactive --profile core)

"$ROOT_DIR/install.sh" "${common[@]}" --display-profile dell-5820 >"$work/selected"
grep -Fq 'Personal display profile: dell-5820 (opt-in)' "$work/selected"
grep -Fq 'Dry run complete; no changes were made.' "$work/selected"

"$ROOT_DIR/install.sh" "${common[@]}" >"$work/default"
grep -Fq 'Personal display profile: none' "$work/default"

if "$ROOT_DIR/install.sh" "${common[@]}" --display-profile unknown \
	>"$work/invalid" 2>&1; then
	printf '%s\n' 'unknown personal display profile was accepted' >&2
	exit 1
fi
grep -Fq 'Unsupported display profile: unknown' "$work/invalid"

printf '%s\n' 'test-install-display-profile: ok'
