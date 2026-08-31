#!/usr/bin/env bash
set -euo pipefail

readonly version=2.2.6
readonly source_name="slick-greeter-${version}.tar.gz"
readonly source_url="https://github.com/linuxmint/slick-greeter/archive/${version}/${source_name}"
readonly source_sha256='f967bde54b174180330e3ddc925377317ae14fe1b53cadf9b4cf11fdcb953379'

script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
topdir=${RPM_TOPDIR:-"$HOME/rpmbuild"}
source_file=${1:-"$topdir/SOURCES/$source_name"}

command -v rpmbuild >/dev/null
command -v sha256sum >/dev/null

if [[ ! -f "$source_file" ]]; then
    command -v curl >/dev/null || {
        printf 'Missing source archive and curl is unavailable: %s\n' "$source_file" >&2
        exit 1
    }
    mkdir -p "$topdir/SOURCES"
    printf 'Downloading pinned Slick Greeter %s source...\n' "$version"
    curl --fail --location --proto '=https' --tlsv1.2 \
        --output "$source_file" "$source_url"
fi

printf '%s  %s\n' "$source_sha256" "$source_file" | sha256sum --check --status || {
    printf 'Source checksum did not match the pinned Slick Greeter %s archive.\n' "$version" >&2
    exit 1
}

mkdir -p "$topdir/SOURCES" "$topdir/SPECS"
if [[ "$source_file" != "$topdir/SOURCES/$source_name" ]]; then
    install -m 0644 "$source_file" "$topdir/SOURCES/$source_name"
fi
install -m 0644 "$script_dir/dwm-jangir-slick-greeter.spec" "$topdir/SPECS/dwm-jangir-slick-greeter.spec"
install -m 0644 "$script_dir/patches/0001-dwm-jangir-greeter-ui.patch" \
    "$topdir/SOURCES/0001-dwm-jangir-greeter-ui.patch"

rpmbuild -ba "$topdir/SPECS/dwm-jangir-slick-greeter.spec"
