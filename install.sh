#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# A real installer run writes one user-owned diagnostic record. Keep only the
# completed most recent run so it is useful to a later support agent without
# accumulating a private system history. Dry runs remain side-effect free.
install_dry_run_requested=false
for install_argument in "$@"; do
	[[ $install_argument == --dry-run ]] && install_dry_run_requested=true
done
case "${DWM_INSTALL_LOG:-auto}" in
auto | 0 | 1) ;;
*)
	printf 'install.sh: ignoring invalid DWM_INSTALL_LOG value: %s\n' "${DWM_INSTALL_LOG}" >&2
	DWM_INSTALL_LOG=auto
	;;
esac
if [[ ${DWM_INSTALL_LOG_ACTIVE:-0} != 1 && $install_dry_run_requested != true &&
	${DWM_INSTALL_LOG:-auto} != 0 &&
	(${DWM_TEST_MODE:-0} != 1 || ${DWM_INSTALL_LOG:-auto} == 1) ]]; then
	install_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dwm-jangir"
	install_log_path="$install_state_dir/install-last.log"
	if mkdir -p "$install_state_dir" && chmod 700 "$install_state_dir" &&
		install_log_tmp=$(mktemp "$install_state_dir/.install-last.XXXXXX"); then
		chmod 600 "$install_log_tmp"
		export DWM_INSTALL_LOG_ACTIVE=1 DWM_INSTALL_LOG_PATH="$install_log_path"
		set +e
		"${BASH:-bash}" "$0" "$@" 2>&1 | tee "$install_log_tmp"
		install_pipeline_status=("${PIPESTATUS[@]}")
		set -e
		install_status=${install_pipeline_status[0]}
		if ((install_status == 0 && install_pipeline_status[1] != 0)); then
			install_status=${install_pipeline_status[1]}
		fi
		if ((install_status == 0)); then
			printf '\nInstaller result: success\n' >>"$install_log_tmp"
		else
			printf '\nInstaller result: failed (exit status %s)\n' "$install_status" >>"$install_log_tmp"
		fi
		if mv -f "$install_log_tmp" "$install_log_path"; then
			printf 'Installer log saved: %s\n' "$install_log_path"
		else
			printf 'install.sh: warning: could not save installer log: %s\n' "$install_log_path" >&2
		fi
		exit "$install_status"
	fi
	printf 'install.sh: warning: could not create the user installer log; continuing without it.\n' >&2
fi

# shellcheck source=scripts/dwm-utils.sh
# shellcheck disable=SC1091
source "$REPO_DIR/scripts/dwm-utils.sh"
# shellcheck source=scripts/dwm-packages.sh
# shellcheck disable=SC1091
source "$REPO_DIR/scripts/dwm-packages.sh"

RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' CYAN='\033[0;36m' NC='\033[0m'
info() { printf "${CYAN}[INFO]${NC} %s\n" "$1"; }
ok() { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
err() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

usage() {
	cat <<EOF
Usage: ./install.sh [options]

Options:
  --profile PROFILE      Install profile: core, recommended, or full.
                         Defaults to DWM_INSTALL_PROFILE or full.
  --display-profile NAME Install an opt-in personal display profile. Supported:
                         dell-5820. It is never selected automatically.
  --non-interactive      Use unattended defaults and do not prompt.
  --yes                  Accept the interactive install summary.
  --install-herdr        Install verified Herdr as an optional workspace.
  --skip-herdr           Do not install Herdr.
  --enable-fedora-gaming-repos
                         Approve the Gamescope COPR and RPM Fusion nonfree.
  --dry-run              Print the resolved plan and exit before changes.
  -h, --help             Show this help.
EOF
}

case "$DISTRO_FAMILY" in
fedora)
	command -v dnf &>/dev/null || {
		err "Fedora was detected, but dnf was not found."
		exit 1
	}
	;;
*)
	err "Unsupported distribution: $DISTRO_NAME"
	err "dwm-jangir supports Fedora only."
	exit 1
	;;
esac

BG_DIR="$HOME/Pictures/backgrounds"
RUNTIME_ID="dwm-jangir"
LEGACY_RUNTIME_ID="dwm-titus"
USER_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
USER_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
USER_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
MANAGED_XORG_CONFIG="/etc/X11/xorg.conf.d/90-${RUNTIME_ID}-display.conf"
LEGACY_XORG_CONFIG="/etc/X11/xorg.conf.d/90-${LEGACY_RUNTIME_ID}-display.conf"
MESLO_VERSION="3.4.0"
MESLO_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${MESLO_VERSION}/Meslo.zip"
MESLO_SHA256="13b502ac8c2bd9d3161018064560e23cd42b175bb730780a270975265a19ad57"
NORDIC_THEME_URL="https://github.com/EliverLara/Nordic.git"
NORDIC_THEME_REF="master"
ARCH="$(uname -m)"
FEDORA_GAMING_COPR="rahuljangirworks/copr-fedora"
INSTALL_PROFILE="${DWM_INSTALL_PROFILE:-full}"
HERDR_INSTALL_MODE="${DWM_INSTALL_HERDR:-false}"
NON_INTERACTIVE=false
ASSUME_YES=false
FEDORA_GAMING_REPOS_APPROVED=false
DRY_RUN=false
DISPLAY_PROFILE=""

while (($# > 0)); do
	case "$1" in
	--profile)
		if (($# < 2)); then
			err "--profile requires a value."
			exit 1
		fi
		INSTALL_PROFILE=$2
		shift 2
		;;
	--profile=*)
		INSTALL_PROFILE=${1#*=}
		shift
		;;
	--display-profile)
		if (($# < 2)); then
			err "--display-profile requires a value."
			exit 1
		fi
		DISPLAY_PROFILE=$2
		shift 2
		;;
	--display-profile=*)
		DISPLAY_PROFILE=${1#*=}
		shift
		;;
	--non-interactive)
		NON_INTERACTIVE=true
		ASSUME_YES=true
		shift
		;;
	--yes)
		ASSUME_YES=true
		shift
		;;
	--install-herdr)
		HERDR_INSTALL_MODE=true
		shift
		;;
	--skip-herdr)
		HERDR_INSTALL_MODE=false
		shift
		;;
	--enable-fedora-gaming-repos)
		FEDORA_GAMING_REPOS_APPROVED=true
		shift
		;;
	--dry-run)
		DRY_RUN=true
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		err "Unknown option: $1"
		usage >&2
		exit 1
		;;
	esac
done

case "$INSTALL_PROFILE" in
core | minimal)
	INSTALL_PROFILE="core"
	;;
recommended | full) ;;
*)
	err "Unsupported DWM_INSTALL_PROFILE: $INSTALL_PROFILE"
	err "Supported profiles: core, recommended, full"
	exit 1
	;;
esac

case "$DISPLAY_PROFILE" in
"" | dell-5820) ;;
*)
	err "Unsupported display profile: $DISPLAY_PROFILE"
	err "Supported display profiles: dell-5820"
	exit 1
	;;
esac

case "$HERDR_INSTALL_MODE" in
auto)
	# Retain compatibility with the old value, but no longer install Herdr by
	# default for any profile.
	HERDR_INSTALL_MODE=false
	;;
1 | true | yes)
	HERDR_INSTALL_MODE=true
	;;
0 | false | no)
	HERDR_INSTALL_MODE=false
	;;
*)
	err "Unsupported DWM_INSTALL_HERDR: $HERDR_INSTALL_MODE"
	err "Supported values: auto, true, false"
	exit 1
	;;
esac

if [[ ! -t 0 || ! -t 1 ]]; then
	NON_INTERACTIVE=true
	ASSUME_YES=true
fi

if [[ $EUID -eq 0 && $DRY_RUN != true ]]; then
	err "Run this installer as a normal user. It invokes sudo only when needed."
	exit 1
fi

install_recommended_profile() {
	[[ $INSTALL_PROFILE == "recommended" || $INSTALL_PROFILE == "full" ]]
}

install_optional_profile() {
	[[ $INSTALL_PROFILE == "full" ]]
}

herdr_arch_supported() {
	case $ARCH in
	x86_64 | amd64 | aarch64 | arm64)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

install_herdr_profile() {
	[[ $HERDR_INSTALL_MODE == true ]] && herdr_arch_supported
}

fedora_gaming_profile() {
	[[ $DISTRO_ID == "fedora" && $INSTALL_PROFILE == "full" && $ARCH == "x86_64" ]]
}

confirm_fedora_gaming_repositories() {
	local answer

	if ! fedora_gaming_profile || [[ $FEDORA_GAMING_REPOS_APPROVED == true ]]; then
		return
	fi
	if [[ $NON_INTERACTIVE == true ]]; then
		warn "Skipping Fedora gaming packages because third-party repositories were not approved."
		warn "Re-run with --enable-fedora-gaming-repos to approve the Gamescope COPR and RPM Fusion nonfree."
		return
	fi

	printf 'Enable the %s COPR and RPM Fusion nonfree for Fedora gaming packages? [y/N] ' \
		"$FEDORA_GAMING_COPR"
	read -r answer
	case "$answer" in
	y | Y | yes | YES)
		FEDORA_GAMING_REPOS_APPROVED=true
		;;
	*)
		warn "Fedora gaming repositories declined; skipping Steam, Gamescope, GameMode, and MangoHud."
		;;
	esac
}

configure_fedora_gaming_repositories() {
	local fedora_release
	local plugin_package
	local rpmfusion_release_url

	if [[ $DISTRO_ID != "fedora" || $INSTALL_PROFILE != "full" || $ARCH != "x86_64" ]]; then
		return 1
	fi
	if [[ $FEDORA_GAMING_REPOS_APPROVED != true ]]; then
		return 1
	fi

	if ! dnf copr --help &>/dev/null; then
		info "Installing the DNF COPR plugin..."
		for plugin_package in dnf5-plugins dnf-plugins-core; do
			if install_packages "$plugin_package"; then
				break
			fi
		done
		if ! dnf copr --help &>/dev/null; then
			warn "Could not install a working DNF COPR plugin; skipping Fedora gaming packages."
			return 1
		fi
	fi

	if ! command -v rpm &>/dev/null; then
		warn "rpm is unavailable; cannot determine the Fedora release for RPM Fusion."
		return 1
	fi
	fedora_release=$(rpm -E '%fedora')
	case "$fedora_release" in
	'' | *[!0-9]*)
		warn "Could not determine the numeric Fedora release for RPM Fusion."
		return 1
		;;
	esac
	rpmfusion_release_url="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_release}.noarch.rpm"
	info "Enabling RPM Fusion nonfree for Steam..."
	if ! sudo dnf install -y "$rpmfusion_release_url"; then
		warn "Could not enable RPM Fusion nonfree; skipping Fedora gaming packages."
		return 1
	fi

	info "Enabling the $FEDORA_GAMING_COPR COPR for the patched Gamescope package..."
	if ! sudo dnf copr enable -y "$FEDORA_GAMING_COPR"; then
		warn "Could not enable $FEDORA_GAMING_COPR; skipping Fedora gaming packages."
		return 1
	fi
}

configure_fedora_gamemode_access() {
	local target_user

	if [[ $DISTRO_ID != "fedora" || $INSTALL_PROFILE != "full" ]]; then
		return
	fi
	if ! getent group gamemode >/dev/null 2>&1; then
		warn "GameMode was not installed; skipping privileged tuning access."
		return
	fi

	target_user=$(id -un)
	if id -nG "$target_user" | tr ' ' '\n' | command grep -Fxq gamemode; then
		ok "$target_user already has GameMode tuning access."
		return
	fi

	info "Adding $target_user to the gamemode group..."
	sudo usermod -aG gamemode "$target_user"
	warn "Log out and back in before using GameMode privileged tuning."
}

package_line() {
	local profile=$1

	dwm_packages "$DISTRO_FAMILY" "$profile" | paste -sd ' ' -
}

print_summary_profile() {
	local label=$1
	local profile=$2
	local packages

	packages="$(package_line "$profile")"
	if [[ -n $packages ]]; then
		printf '  %s: %s\n' "$label" "$packages"
	else
		printf '  %s: none\n' "$label"
	fi
}

print_install_summary() {
	echo ""
	echo "Installation summary:"
	printf '  Distribution: %s\n' "$DISTRO_NAME"
	printf '  Family: %s\n' "$DISTRO_FAMILY"
	printf '  Package manager: %s\n' "$PKG_CMD"
	printf '  Profile: %s\n' "$INSTALL_PROFILE"
	if [[ -n $DISPLAY_PROFILE ]]; then
		printf '  Personal display profile: %s (opt-in)\n' "$DISPLAY_PROFILE"
	else
		printf '  Personal display profile: none\n'
	fi
	printf '  Mode: %s\n' "$([[ $NON_INTERACTIVE == true ]] && echo non-interactive || echo interactive)"
	print_summary_profile "Required packages" required
	if install_recommended_profile; then
		print_summary_profile "Recommended packages" recommended
		printf '  Gear Lever: user-scoped Flathub install (%s)\n' 'it.mijorus.gearlever'
	else
		printf '  Recommended packages: skipped\n'
	fi
	if install_optional_profile; then
		print_summary_profile "Optional extras" optional
		if fedora_gaming_profile; then
			print_summary_profile "Fedora gaming packages" gaming
			if [[ $FEDORA_GAMING_REPOS_APPROVED == true ]]; then
				printf '  Third-party repositories: approved\n'
			else
				printf '  Third-party repositories: require separate confirmation\n'
			fi
		fi
	else
		printf '  Optional extras: skipped\n'
	fi
	print_summary_profile "Terminal candidates" terminal
	if install_herdr_profile; then
		printf '  Herdr workspace: verified user install from https://herdr.dev/install.sh\n'
	elif [[ $HERDR_INSTALL_MODE == true ]]; then
		printf '  Herdr workspace: skipped (unsupported architecture: %s)\n' "$ARCH"
	else
		printf '  Herdr workspace: skipped (optional; use --install-herdr to enable)\n'
	fi
	echo ""
}

confirm_install_summary() {
	local answer

	print_install_summary

	if [[ $DRY_RUN == true ]]; then
		ok "Dry run complete; no changes were made."
		exit 0
	fi

	if [[ $ASSUME_YES == true ]]; then
		return
	fi

	printf 'Continue with installation? [y/N] '
	read -r answer
	case "$answer" in
	y | Y | yes | YES) ;;
	*)
		err "Installation cancelled."
		exit 1
		;;
	esac
}

meslo_nerd_font_installed() {
	local resolved_family
	command -v fc-match >/dev/null 2>&1 || return 1
	resolved_family=$(fc-match --format '%{family[0]}\n' \
		'MesloLGS Nerd Font Mono:charset=20-7e' 2>/dev/null || true)
	case $resolved_family in
	'MesloLGS Nerd Font Mono' | 'MesloLGS Nerd Font' | 'MesloLGS NF') return 0 ;;
	*) return 1 ;;
	esac
}

install_meslo_nerd_font() {
	local font_dir="$HOME/.local/share/fonts/Meslo"
	local tmp_dir
	local archive

	if meslo_nerd_font_installed; then
		ok "MesloLGS Nerd Font is already installed."
		return
	fi

	tmp_dir="$(mktemp -d)"
	archive="$tmp_dir/Meslo.zip"

	info "Downloading Meslo Nerd Font v${MESLO_VERSION}..."
	if ! curl --fail --location --show-error --silent "$MESLO_URL" --output "$archive"; then
		rm -rf "$tmp_dir"
		err "Failed to download Meslo Nerd Font."
		return 1
	fi

	if ! printf '%s  %s\n' "$MESLO_SHA256" "$archive" | sha256sum --check --status; then
		rm -rf "$tmp_dir"
		err "Meslo Nerd Font checksum verification failed."
		return 1
	fi

	mkdir -p "$font_dir"
	unzip -j -q -o "$archive" '*.ttf' -d "$font_dir"
	rm -rf "$tmp_dir"
	fc-cache -f "$font_dir" >/dev/null 2>&1
	ok "MesloLGS Nerd Font installed."
}

install_nordic_gtk_theme() {
	local target="/usr/share/themes/Nordic"
	local tmp_dir

	if [[ -d "$target/gtk-3.0" || -d "$target/gtk-4.0" ]]; then
		ok "Nordic GTK theme is already installed system-wide."
		return 0
	fi

	if ! command -v git &>/dev/null; then
		warn "git is unavailable; skipping Nordic GTK theme install."
		return 1
	fi

	tmp_dir="$(mktemp -d)"
	if ! git clone --depth 1 --branch "$NORDIC_THEME_REF" "$NORDIC_THEME_URL" "$tmp_dir/Nordic" 2>/dev/null; then
		rm -rf "$tmp_dir"
		warn "Could not download Nordic GTK theme; continuing without it."
		return 1
	fi

	sudo rm -rf "$target"
	sudo install -d -m 0755 /usr/share/themes
	sudo cp -a "$tmp_dir/Nordic" "$target"
	sudo find "$target" -type d -exec chmod 0755 {} +
	sudo find "$target" -type f -exec chmod 0644 {} +
	rm -rf "$tmp_dir"
	ok "Nordic GTK theme installed system-wide."
}

install_supported_terminal() {
	if ! dwm_install_first_available_profile terminal; then
		err "No supported terminal is available in the enabled repositories."
		return 1
	fi
}

configure_quickshell_picom_opacity() {
	local config="/etc/xdg/picom.conf"
	local backup="${config}.dwm-jangir.bak"
	local tooltip_rule="^([[:space:]]*\"[0-9]+([.][0-9]+)?:window_type = 'tooltip')(\"[[:space:]]*,?[[:space:]]*)$"
	local configured_rule="^[[:space:]]*\"[0-9]+([.][0-9]+)?:window_type = 'tooltip' && name != 'quickshell'\"[[:space:]]*,?[[:space:]]*$"
	local tmp

	if [[ ! -f $config ]]; then
		warn "Picom system config not found; skipping Quickshell opacity override."
		return
	fi
	if sudo grep -Eq "$configured_rule" "$config"; then
		ok "Quickshell Picom opacity is already configured."
		return
	fi
	if ! sudo grep -Eq "$tooltip_rule" "$config"; then
		warn "Recognized Picom tooltip opacity rule not found; preserving $config."
		return
	fi

	tmp="$(mktemp)"
	if ! sudo sed -E \
		"s/${tooltip_rule}/\\1 \&\& name != 'quickshell'\\3/" \
		"$config" | tee "$tmp" >/dev/null; then
		rm -f "$tmp"
		warn "Could not prepare the Quickshell Picom opacity override."
		return
	fi

	if [[ ! -f $backup ]]; then
		sudo install -o root -g root -m 0644 "$config" "$backup"
	fi
	sudo install -o root -g root -m 0644 "$tmp" "$config"
	rm -f "$tmp"
	ok "Configured fully opaque Quickshell windows in Picom."
}

configure_displays_after_install() {
	local answer

	[[ -z $DISPLAY_PROFILE ]] || return 0

	if [[ $NON_INTERACTIVE == true ]]; then
		warn "Display setup deferred for non-interactive installation."
		warn "Run dwm-display-setup from an X11 session after login."
		return 0
	fi
	if [[ -z ${DISPLAY:-} ]] || ! command -v xrandr >/dev/null 2>&1; then
		warn "Display setup needs an active X11 session and was deferred."
		warn "After login, run: dwm-display-setup"
		return 0
	fi
	if ! xrandr --query 2>/dev/null | awk '$2 == "connected" { found = 1 } END { exit !found }'; then
		warn "No connected X11 outputs were detected; display setup was deferred."
		return 0
	fi

	printf 'Configure persistent display resolution and positioning now? [Y/n] '
	read -r answer
	case $answer in
	n | N | no | NO)
		warn "Display setup skipped. Run dwm-display-setup when ready."
		;;
	*)
		if ! "$REPO_DIR/scripts/dwm-display-setup" wizard; then
			warn "Display setup did not complete. Existing Xorg configuration was preserved."
			warn "Run dwm-display-setup to try again."
		fi
		;;
	esac
}

configure_selected_display_profile_after_install() {
	local profile_path answer

	[[ -n $DISPLAY_PROFILE ]] || return 0
	profile_path=$("$REPO_DIR/scripts/dwm-personal-display-profile" prepare "$DISPLAY_PROFILE") || {
		warn "The selected $DISPLAY_PROFILE profile was not written; existing user configuration was preserved."
		return 0
	}

	info "Selected personal display profile: $DISPLAY_PROFILE"
	printf '  %s\n' "$profile_path"
	if [[ $NON_INTERACTIVE != true ]]; then
		printf 'Validate and install this profile through dwm-display-setup? [y/N] '
		read -r answer
		case $answer in
		y | Y | yes | YES) ;;
		*)
			warn "Profile was saved but not applied. Run dwm-display-setup when ready."
			return 0
			;;
		esac
	fi

	if [[ -z ${DISPLAY:-} ]]; then
		warn "Profile was saved but no active X11 session is available, so it was not applied."
		warn "After login, run: dwm-display-setup install $profile_path"
		return 0
	fi
	if ! "$REPO_DIR/scripts/dwm-personal-display-profile" validate "$DISPLAY_PROFILE" "$profile_path"; then
		warn "The selected profile does not match this active hardware and was not applied."
		warn "Run dwm-display-setup for the normal display wizard."
		return 0
	fi

	if [[ $NON_INTERACTIVE == true ]]; then
		"$REPO_DIR/scripts/dwm-display-setup" install --no-preview --yes "$profile_path" || {
			warn "Could not install the selected profile; the existing display configuration was preserved."
			return 0
		}
	else
		"$REPO_DIR/scripts/dwm-display-setup" install "$profile_path" || {
			warn "The selected profile was not accepted; the existing display configuration was preserved."
			return 0
		}
	fi
	ok "Installed persistent display profile: $DISPLAY_PROFILE"
}

# Move only complete, unambiguous user-owned runtime directories.  When both
# names exist we copy only missing files and retain the legacy directory if it
# still contains a divergent file; an installer must never discard settings.
migrate_user_runtime_directory() {
	local legacy=$1 current=$2
	[[ -e $legacy ]] || return 0
	if [[ ! -e $current ]]; then
		mv -- "$legacy" "$current"
		ok "Migrated ${legacy#"$HOME"/} to ${current#"$HOME"/}."
		return 0
	fi
	if [[ ! -d $legacy || ! -d $current ]]; then
		warn "Cannot safely merge legacy path $legacy into $current; preserving both."
		return 0
	fi
	cp -aL -n --no-preserve=ownership "$legacy"/. "$current"/
	if diff -qr -- "$legacy" "$current" >/dev/null 2>&1; then
		rm -rf -- "$legacy"
		ok "Merged and removed legacy ${legacy#"$HOME"/}."
	else
		warn "Legacy settings remain at $legacy because they differ from $current."
		warn "Review and merge them manually; they were not overwritten or deleted."
	fi
}

migrate_user_runtime_identity() {
	migrate_user_runtime_directory "$USER_CONFIG_HOME/$LEGACY_RUNTIME_ID" \
		"$USER_CONFIG_HOME/$RUNTIME_ID"
	migrate_user_runtime_directory "$USER_DATA_HOME/$LEGACY_RUNTIME_ID" \
		"$USER_DATA_HOME/$RUNTIME_ID"
	migrate_user_runtime_directory "$USER_STATE_HOME/$LEGACY_RUNTIME_ID" \
		"$USER_STATE_HOME/$RUNTIME_ID"
}

# The data directory is a managed checkout copy, not a user configuration
# location. Once install-user has created its replacement, keeping an older
# copy only risks helpers accidentally loading stale code.
cleanup_legacy_user_runtime() {
	local legacy_data="$USER_DATA_HOME/$LEGACY_RUNTIME_ID"
	local current_data="$USER_DATA_HOME/$RUNTIME_ID"
	local legacy_state="$USER_STATE_HOME/$LEGACY_RUNTIME_ID"
	local current_state="$USER_STATE_HOME/$RUNTIME_ID"
	local state_difference

	if [[ -d $legacy_data && ! -L $legacy_data &&
		-d $current_data/config && -d $current_data/scripts ]]; then
		rm -rf -- "$legacy_data"
		ok "Removed stale managed data directory: $legacy_data"
	fi
	if [[ -d $legacy_state && ! -L $legacy_state && -d $current_state ]]; then
		state_difference=$(diff -qr -- "$legacy_state" "$current_state" 2>/dev/null || true)
		if [[ -z $(printf '%s\n' "$state_difference" |
			grep -Fv "Only in $current_state:" || true) ]]; then
			rm -rf -- "$legacy_state"
			ok "Removed migrated legacy state directory: $legacy_state"
		else
			warn "Legacy state remains at $legacy_state because it has files not present in $current_state."
		fi
	fi
}

# A display fragment is system-owned and influences the next login.  Rename it
# before installing a profile so there can never be two managed fragments.
migrate_managed_xorg_identity() {
	local legacy_backup current_backup
	if [[ -e $LEGACY_XORG_CONFIG ]]; then
		if [[ ! -e $MANAGED_XORG_CONFIG ]]; then
			sudo mv -- "$LEGACY_XORG_CONFIG" "$MANAGED_XORG_CONFIG"
			ok "Migrated persistent display configuration to $MANAGED_XORG_CONFIG."
		elif sudo cmp -s -- "$LEGACY_XORG_CONFIG" "$MANAGED_XORG_CONFIG"; then
			sudo rm -f -- "$LEGACY_XORG_CONFIG"
			ok "Removed duplicate legacy display configuration."
		else
			warn "Both managed display fragments differ; preserving $LEGACY_XORG_CONFIG."
			warn "Resolve it before rebooting so only $MANAGED_XORG_CONFIG remains."
		fi
	fi
	shopt -s nullglob
	for legacy_backup in "$LEGACY_XORG_CONFIG".backup.*; do
		current_backup="${legacy_backup/$LEGACY_RUNTIME_ID/$RUNTIME_ID}"
		[[ -e $current_backup ]] || sudo mv -- "$legacy_backup" "$current_backup"
	done
	shopt -u nullglob
}

remove_legacy_system_runtime() {
	local legacy_libexec="/usr/local/libexec/$LEGACY_RUNTIME_ID"
	local legacy_release="/usr/local/bin/${LEGACY_RUNTIME_ID}-release"
	local legacy_session="/usr/share/xsessions/dwm.desktop"
	local legacy_license="/usr/share/licenses/$LEGACY_RUNTIME_ID/capitaine-cursors"
	local legacy_asset legacy_lightdm_backup current_lightdm_backup

	[[ -x /usr/local/libexec/$RUNTIME_ID/dwm-settings-display-root ]] || {
		warn "New privileged helper is missing; legacy system files were preserved."
		return 0
	}
	if [[ -d $legacy_libexec && ! -L $legacy_libexec ]]; then
		sudo rm -rf -- "$legacy_libexec"
		ok "Removed legacy privileged helper directory: $legacy_libexec"
	fi
	if [[ -f $legacy_release && ! -L $legacy_release ]]; then
		sudo rm -f -- "$legacy_release"
		ok "Removed legacy release helper: $legacy_release"
	fi
	if [[ -f $legacy_session ]] &&
		sudo grep -Fqx 'Exec=/usr/local/bin/dwm-session' "$legacy_session"; then
		sudo rm -f -- "$legacy_session"
		ok "Removed legacy dwm session entry: $legacy_session"
	fi
	if [[ -d $legacy_license && ! -L $legacy_license ]]; then
		sudo rm -rf -- "$legacy_license"
	fi
	for legacy_asset in \
		/usr/share/pixmaps/${LEGACY_RUNTIME_ID}.jpg \
		/usr/share/pixmaps/${LEGACY_RUNTIME_ID}-logo.png; do
		[[ -f $legacy_asset && ! -L $legacy_asset ]] || continue
		sudo rm -f -- "$legacy_asset"
	done
	shopt -s nullglob
	for legacy_lightdm_backup in /etc/lightdm/lightdm.conf."$LEGACY_RUNTIME_ID".*.bak; do
		current_lightdm_backup="${legacy_lightdm_backup/$LEGACY_RUNTIME_ID/$RUNTIME_ID}"
		[[ -e $current_lightdm_backup ]] || sudo mv -- "$legacy_lightdm_backup" "$current_lightdm_backup"
	done
	shopt -u nullglob
}

detect_display_manager() {
	local unit

	unit="$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)"
	case "$(basename "$unit")" in
	lightdm.service)
		echo "lightdm"
		return
		;;
	gdm.service)
		echo "gdm"
		return
		;;
	sddm.service)
		echo "sddm"
		return
		;;
	esac

	for unit in lightdm gdm sddm; do
		if command -v "$unit" &>/dev/null; then
			echo "$unit"
			return
		fi
	done
}

print_install_preflight() {
	local profile_path existing_dwm current_dm active_outputs revision dirty_count
	local -a xorg_backups=()

	echo ""
	echo "Preflight inspection (read-only):"
	printf '  Repository checkout: %s\n' "$REPO_DIR"
	if command -v git >/dev/null 2>&1 &&
		revision=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null); then
		dirty_count=$(git -C "$REPO_DIR" status --porcelain 2>/dev/null | wc -l)
		printf '  Repository revision: %s (%s changed worktree path(s))\n' "$revision" "$dirty_count"
	fi
	if existing_dwm=$(command -v dwm 2>/dev/null); then
		printf '  Existing dwm command: %s\n' "$existing_dwm"
	else
		printf '  Existing dwm command: not found\n'
	fi
	if [[ -x $REPO_DIR/dwm ]]; then
		printf '  Checkout build: present\n'
	else
		printf '  Checkout build: not built yet\n'
	fi
	if [[ -f $REPO_DIR/config.h ]]; then
		printf '  Build configuration: existing config.h will be preserved\n'
	else
		printf '  Build configuration: config.h will be created by the installer\n'
	fi
	if [[ -d $USER_CONFIG_HOME/$RUNTIME_ID ]]; then
		printf '  User dwm configuration: existing XDG configuration detected\n'
	elif [[ -d $USER_CONFIG_HOME/$LEGACY_RUNTIME_ID ]]; then
		printf '  User dwm configuration: legacy %s configuration will be migrated\n' "$LEGACY_RUNTIME_ID"
	else
		printf '  User dwm configuration: no existing XDG configuration\n'
	fi
	current_dm=$(detect_display_manager)
	printf '  Display manager: %s\n' "${current_dm:-not detected}"
	if [[ -f $MANAGED_XORG_CONFIG ]]; then
		printf '  Persistent display configuration: existing managed Xorg fragment\n'
	elif [[ -f $LEGACY_XORG_CONFIG ]]; then
		printf '  Persistent display configuration: legacy fragment will be migrated\n'
	else
		printf '  Persistent display configuration: no managed Xorg fragment\n'
	fi
	shopt -s nullglob
	xorg_backups=("$MANAGED_XORG_CONFIG".backup.*)
	shopt -u nullglob
	printf '  Managed Xorg backups: %d\n' "${#xorg_backups[@]}"
	if [[ -n $DISPLAY_PROFILE ]]; then
		profile_path="$USER_CONFIG_HOME/$RUNTIME_ID/display-profiles/${DISPLAY_PROFILE}.conf"
		printf '  Selected display profile: %s\n' "$profile_path"
	fi
	if [[ -n ${DWM_INSTALL_LOG_PATH:-} && -f ${DWM_INSTALL_LOG_PATH} ]]; then
		printf '  Previous installer record: %s\n' "$DWM_INSTALL_LOG_PATH"
	fi
	if [[ -n ${DISPLAY:-} ]] && command -v xrandr >/dev/null 2>&1; then
		active_outputs=$(xrandr --query 2>/dev/null | awk '$2 == "connected" { printf "%s ", $1 }' || true)
		printf '  Active X11 outputs: %s\n' "${active_outputs:-unavailable}"
	else
		printf '  Active X11 outputs: no active X11 session\n'
	fi
}

install_lightdm_config() {
	local lightdm_config="/etc/lightdm/lightdm.conf"
	local lightdm_seat_section="SeatDefaults"
	local lightdm_greeter_session="lightdm-slick-greeter"
	local lightdm_session_wrapper="/etc/lightdm/Xsession"
	local lightdm_logind_check=false

	lightdm_seat_section="Seat:*"
	lightdm_greeter_session="slick-greeter"
	lightdm_session_wrapper=""
	lightdm_logind_check=true

	sudo make -C "$REPO_DIR/lightdm" \
		LIGHTDM_SEAT_SECTION="$lightdm_seat_section" \
		LIGHTDM_GREETER_SESSION="$lightdm_greeter_session" \
		LIGHTDM_SESSION_WRAPPER="$lightdm_session_wrapper" \
		LIGHTDM_LOGIND_CHECK="$lightdm_logind_check" \
		install
	if command -v restorecon &>/dev/null; then
		sudo restorecon \
			"$lightdm_config" \
			/etc/lightdm/slick-greeter.conf \
			/usr/share/pixmaps/dwm-jangir.jpg \
			/usr/share/pixmaps/dwm-jangir-logo.png
	fi
}

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║            dwm-jangir Installer           ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Distribution: $DISTRO_NAME"
info "Family: $DISTRO_FAMILY"
info "Package manager: $PKG_CMD"
info "Install profile: $INSTALL_PROFILE"
print_install_preflight
confirm_install_summary
confirm_fedora_gaming_repositories

if [[ $NON_INTERACTIVE != true ]]; then
	"$REPO_DIR/scripts/configure-build.sh"
else
	"$REPO_DIR/scripts/configure-build.sh" --non-interactive
fi

# ── Required build and runtime dependencies ──────────────
info "Installing required build and runtime dependencies..."
dwm_install_package_profile build
dwm_install_package_profile x11
dwm_install_package_profile runtime-required
ok "Required build and runtime dependencies installed."

# ── Recommended desktop dependencies ─────────────────────
if install_recommended_profile; then
	info "Installing recommended desktop dependencies..."
	dwm_install_package_profile desktop
	if ! env -u DWM_TEST_MODE -u DWM_TEST_QUICKSHELL_VERSION \
		"$REPO_DIR/scripts/dwm-quickshell-version-check"; then
		err "The installed Quickshell build is incompatible with dwm-jangir."
		exit 1
	fi
	if ! dwm_install_available_package_profile screenshot-optional; then
		warn "maim is unavailable in the enabled repositories; screenshot hotkeys will remain disabled."
	fi
	dwm_install_package_profile theme
	if ! dwm_install_available_package_profile theme-gtk; then
		warn "Some GTK theme packages were unavailable in enabled repositories."
	fi
	install_nordic_gtk_theme || true
	dwm_install_package_profile fonts
	info "Setting up Gear Lever for AppImage management..."
	if "$REPO_DIR/scripts/install-gearlever"; then
		ok "Gear Lever is installed."
	else
		warn "Gear Lever setup failed; retry with scripts/install-gearlever when Flathub is reachable."
	fi
	ok "Recommended desktop dependencies installed."
else
	warn "Skipping recommended desktop dependencies for core profile."
fi

if command -v picom >/dev/null 2>&1; then
	configure_quickshell_picom_opacity
fi

# ── Optional desktop extras ──────────────────────────────
if install_optional_profile; then
	info "Installing optional desktop extras..."
	if ! dwm_install_available_package_profile optional; then
		warn "Some optional desktop extras were unavailable in enabled repositories."
	fi
	if fedora_gaming_profile; then
		if [[ $FEDORA_GAMING_REPOS_APPROVED != true ]]; then
			warn "Fedora gaming packages were skipped because their repositories were not approved."
		elif configure_fedora_gaming_repositories; then
			info "Installing Fedora gaming packages..."
			if ! dwm_install_available_package_profile gaming; then
				warn "Some Fedora gaming packages were unavailable in the approved repositories."
			fi
			configure_fedora_gamemode_access
		else
			warn "Fedora gaming repository setup failed; no gaming packages were installed."
		fi
	fi
	ok "Optional desktop extras processed."
else
	warn "Skipping optional desktop extras for $INSTALL_PROFILE profile."
fi

# ── Qt / GTK theming ─────────────────────────────────────
if install_recommended_profile; then
	info "Configuring Qt/GTK dark-mode dependencies..."
	# dconf: required for gsettings to persist GTK color-scheme changes
	# qt6ct / qt5ct: QT_QPA_PLATFORMTHEME backend for Qt dark mode in standalone WMs
	dwm_install_first_available_profile theme-optional ||
		warn "Neither qt6ct nor qt5ct is available - Qt apps may not respect dark mode."
	ok "Qt/GTK theming dependencies configured."
fi

# ── Fonts ────────────────────────────────────────────────
if install_recommended_profile; then
	info "Installing fonts..."
	FONT_DIR="$HOME/.local/share/fonts"
	mkdir -p "$FONT_DIR"
	install_meslo_nerd_font
	ok "Fonts installed."
fi

# ── Terminal emulator ────────────────────────────────────
terminal=""
if command -v alacritty &>/dev/null; then
	terminal="alacritty"
	ok "Preferred terminal already installed: $terminal"
else
	info "Installing the preferred Alacritty terminal from enabled repositories..."
	if dwm_install_first_available_profile terminal-primary; then
		terminal="alacritty"
		ok "Preferred terminal installed: $terminal"
	else
		warn "Alacritty is unavailable; falling back to another supported terminal."
		for t in kitty st warp-terminal xterm; do command -v "$t" &>/dev/null && {
			terminal="$t"
			break
		}; done
		if [ -z "$terminal" ]; then
			install_supported_terminal
			terminal="$(detect_terminal)"
		fi
	fi
fi

# ── Herdr terminal workspace ─────────────────────────────
if install_herdr_profile; then
	info "Installing the verified Herdr workspace for interactive terminals..."
	if "$REPO_DIR/scripts/install-herdr"; then
		ok "Herdr is installed; set DWM_HERDR=1 and use dwm-terminal to open it in $terminal."
	else
		herdr_status=$?
		if [[ $herdr_status -eq 2 ]]; then
			warn "Herdr is ready, but one or more detected agent integrations could not be installed."
		else
			warn "Herdr installation failed; Alacritty remains the default terminal."
		fi
	fi
elif [[ $HERDR_INSTALL_MODE == true ]]; then
	warn "Skipping Herdr installation on unsupported architecture: $ARCH."
fi

# ── XDG dirs + wallpapers ────────────────────────────────
if install_optional_profile && command -v xdg-user-dirs-update &>/dev/null; then
	xdg-user-dirs-update
fi

if install_optional_profile; then
	mkdir -p "$HOME/Pictures"
	if [ ! -d "$BG_DIR" ]; then
		info "Downloading Nord wallpapers..."
		if git clone https://github.com/rahuljangirworks/background.git "$BG_DIR" 2>/dev/null; then
			ok "Wallpapers downloaded to $BG_DIR"
		else
			warn "Failed to download wallpapers. Add your own to $BG_DIR."
		fi
	else
		ok "Wallpapers already present."
	fi
fi

# ── Display manager ──────────────────────────────────────
currentdm="$(detect_display_manager)"

if [ -n "$currentdm" ]; then
	ok "Display manager already installed: $currentdm"
elif ! install_optional_profile; then
	warn "No display manager found; skipping display-manager installation for $INSTALL_PROFILE profile."
else
	info "No display manager found - installing LightDM..."
	dwm_install_package_profile lightdm
	sudo systemctl enable lightdm.service
	currentdm="lightdm"
	ok "LightDM installed and enabled."
fi

# ── LightDM greeter config ───────────────────────────────
if [[ $currentdm == "lightdm" ]]; then
	info "Deploying LightDM Slick Greeter config..."
	install_lightdm_config
	ok "LightDM config deployed."
fi

# ── Build & Install ──────────────────────────────────────
cd "$REPO_DIR"
make clean
make
sudo make install-system \
	USER_HOME="$HOME" \
	OWNER="$(id -un)" \
	DATADIR="/usr/share"
migrate_user_runtime_identity
make install-user \
	USER_HOME="$HOME" \
	OWNER="$(id -un)" \
	XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" \
	XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
cleanup_legacy_user_runtime
migrate_managed_xorg_identity
configure_displays_after_install
configure_selected_display_profile_after_install
remove_legacy_system_runtime

# ── Done ─────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║          Installation Complete!           ║"
echo "╚═══════════════════════════════════════════╝"
echo ""
info "Detected: $DISTRO_NAME"
echo "  • Build configuration: $REPO_DIR/config.h"
echo "  • Reconfigure by removing config.h and running the installer again"
echo "  • Display setup: dwm-display-setup"
if [[ -n ${DWM_INSTALL_LOG_PATH:-} ]]; then
	echo "  • Installer record: $DWM_INSTALL_LOG_PATH"
fi
echo "  • Log out and select 'dwm-jangir', or start with: startx"
if [[ $currentdm == "lightdm" ]]; then
	echo "  • Start LightDM now (optional): sudo systemctl start lightdm.service"
fi
echo ""
echo "  SUPER+/   keybind viewer     SUPER+X  terminal"
echo "  SUPER+F1  control center     SUPER+R  app launcher"
echo "  SUPER+Q   close window"
echo ""
echo "  Full reference: docs/src/keybinds.md or SUPER+/ in dwm"
echo ""
