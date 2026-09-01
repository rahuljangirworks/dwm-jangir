#!/usr/bin/env bash
# Test: Verify system is safe to reboot or relogin
# Purpose: Check all critical components are installed and configured correctly
# shellcheck disable=SC2329

set -uo pipefail

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo ".")}"
RUNTIME_ID="${RUNTIME_ID:-dwm-jangir}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILED_CHECKS=0
TOTAL_CHECKS=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    "$@"
}

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         REBOOT/RELOGIN SAFETY VERIFICATION                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check 1: dwm binary exists and is executable
check_dwm_binary() {
    echo "Checking dwm binary..."
    if [ -x /usr/local/bin/dwm ]; then
        local version
        version=$(/usr/local/bin/dwm -v 2>&1 | head -1)
        pass "dwm binary installed: $version"
    else
        fail "dwm binary missing or not executable at /usr/local/bin/dwm"
    fi
}

# Check 2: Session script exists
check_session_script() {
    echo "Checking session script..."
    if [ -x /usr/local/bin/dwm-session ]; then
        pass "Session script installed and executable"
    else
        fail "Session script missing at /usr/local/bin/dwm-session"
    fi
}

# Check 3: LightDM session entry
check_lightdm_session() {
    echo "Checking LightDM session entry..."
    local session_file="/usr/share/xsessions/${RUNTIME_ID}.desktop"
    if [ -f "$session_file" ]; then
        if grep -q "Exec=/usr/local/bin/dwm-session" "$session_file" 2>/dev/null; then
            pass "LightDM session entry configured correctly"
        else
            fail "LightDM session entry exists but Exec line incorrect"
        fi
    else
        fail "LightDM session file missing: $session_file"
    fi
}

# Check 4: User directories exist
check_user_directories() {
    echo "Checking user directories..."
    local user_home="${HOME}"
    local dirs=(
        "$user_home/.config/${RUNTIME_ID}"
        "$user_home/.local/share/${RUNTIME_ID}"
        "$user_home/.local/state/${RUNTIME_ID}"
    )

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            pass "Directory exists: $dir"
        else
            fail "Directory missing: $dir"
        fi
    done
}

# Check 5: No legacy dwm-titus conflicts
check_no_legacy_conflicts() {
    echo "Checking for legacy dwm-titus conflicts..."
    local user_home="${HOME}"
    local legacy_dirs=(
        "$user_home/.local/share/dwm-titus"
        "$user_home/.local/state/dwm-titus"
    )

    local conflicts_found=false
    for dir in "${legacy_dirs[@]}"; do
        if [ -e "$dir" ]; then
            warn "Legacy directory still exists: $dir"
            conflicts_found=true
        fi
    done

    if [ "$conflicts_found" = false ]; then
        pass "No legacy dwm-titus directories found"
    fi
}

# Check 6: Display configuration exists (if NVIDIA)
check_display_configuration() {
    echo "Checking display configuration..."
    local xorg_conf="/etc/X11/xorg.conf.d/90-${RUNTIME_ID}-display.conf"

    if [ -f "$xorg_conf" ]; then
        if command -v nvidia-smi &>/dev/null; then
            # NVIDIA GPU present, check for MetaModes
            if grep -q "MetaModes" "$xorg_conf" 2>/dev/null; then
                pass "Display configuration with NVIDIA MetaModes present"
            else
                warn "Display configuration exists but no MetaModes found"
            fi
        else
            pass "Display configuration present"
        fi
    else
        warn "No managed Xorg display configuration found (may be first install)"
    fi
}

# Check 7: Critical scripts installed
check_critical_scripts() {
    echo "Checking critical scripts..."
    local critical_scripts=(
        "dwm-session"
        "dwm-display-setup"
        "dwm-settings"
        "dwm-status"
        "dwm-terminal"
    )

    for script in "${critical_scripts[@]}"; do
        if command -v "$script" &>/dev/null; then
            pass "Script available: $script"
        else
            fail "Script missing: $script"
        fi
    done
}

# Check 8: Quickshell configuration exists
check_quickshell_config() {
    echo "Checking Quickshell configuration..."
    local qs_config="${HOME}/.local/share/${RUNTIME_ID}/config/quickshell"

    if [ -d "$qs_config" ]; then
        if [ -f "$qs_config/shell.qml" ]; then
            pass "Quickshell configuration present"
        else
            warn "Quickshell directory exists but shell.qml missing"
        fi
    else
        fail "Quickshell configuration directory missing"
    fi
}

# Check 9: Installation log exists and shows success
check_installation_log() {
    echo "Checking installation log..."
    local install_log="${HOME}/.local/state/${RUNTIME_ID}/install-last.log"

    if [ -f "$install_log" ]; then
        if grep -q "Installation Complete" "$install_log" 2>/dev/null; then
            pass "Last installation completed successfully"
        else
            warn "Installation log exists but completion status unclear"
        fi
    else
        warn "No installation log found"
    fi
}

# Check 10: LightDM is installed and available
check_lightdm_installed() {
    echo "Checking LightDM availability..."
    if command -v lightdm &>/dev/null; then
        pass "LightDM is installed"
    else
        fail "LightDM not found (required for graphical login)"
    fi
}

# Run all checks
echo "═══════════════════════════════════════════════════════════════"
echo "Running safety checks..."
echo "═══════════════════════════════════════════════════════════════"
echo ""

check check_dwm_binary
echo ""
check check_session_script
echo ""
check check_lightdm_session
echo ""
check check_user_directories
echo ""
check check_no_legacy_conflicts
echo ""
check check_display_configuration
echo ""
check check_critical_scripts
echo ""
check check_quickshell_config
echo ""
check check_installation_log
echo ""
check check_lightdm_installed
echo ""

# Summary
echo "═══════════════════════════════════════════════════════════════"
echo "VERIFICATION SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Total checks: $TOTAL_CHECKS"
echo "Failed checks: $FAILED_CHECKS"
echo ""

if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "${GREEN}✅ SAFE TO REBOOT/RELOGIN${NC}"
    echo ""
    echo "All critical components verified. You can safely:"
    echo "  • Press SUPER + SHIFT + Q to restart dwm (quick)"
    echo "  • Log out and log back in (full restart)"
    echo "  • Reboot the system"
    echo ""
    exit 0
else
    echo -e "${RED}❌ NOT SAFE TO REBOOT/RELOGIN${NC}"
    echo ""
    echo "Found $FAILED_CHECKS critical issue(s)."
    echo "Please fix the failed checks before rebooting."
    echo ""
    exit 1
fi
