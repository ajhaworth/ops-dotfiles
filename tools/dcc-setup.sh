#!/usr/bin/env bash
#
# dcc-setup.sh - DCC (Digital Content Creation) application config management
#
# Sets up Blender and Houdini configurations by symlinking managed config
# files to the appropriate version-specific directories.
#
# Usage:
#   ./tools/dcc-setup.sh [options]
#
# Options:
#   --app <name>        Install specific app only (blender, houdini)
#   --version <ver>     Target specific version (e.g., 4.2, 20.5)
#   --dry-run           Preview changes
#   --backup            Backup existing configs first
#   --restore           Restore from backup
#   --list              List detected versions
#   --help              Show this help message
#

set -euo pipefail

# Get the directory where this script is located
DCC_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DCC_SCRIPT_DIR/.." && pwd)"

# Source libraries
source "$REPO_ROOT/lib/common.sh"
source "$REPO_ROOT/lib/detect.sh"
source "$REPO_ROOT/lib/prompt.sh"
source "$DCC_SCRIPT_DIR/lib/dcc-common.sh"

# Default options
APP=""
VERSION=""
DRY_RUN="${DRY_RUN:-false}"
DO_BACKUP="false"
DO_RESTORE="false"
LIST_ONLY="false"

# Export for subshells
export DRY_RUN

# Show help
show_help() {
    cat << EOF
Usage: ./tools/dcc-setup.sh [options]

DCC (Digital Content Creation) application config management.
Sets up Blender and Houdini configurations.

Options:
    --app <name>        Install specific app only (blender, houdini)
    --version <ver>     Target specific version (e.g., 4.2, 20.5)
    --dry-run           Preview changes without making them
    --backup            Backup existing configs before making changes
    --restore           Restore configs from backup
    --list              List detected DCC versions and exit
    --help              Show this help message

Examples:
    ./tools/dcc-setup.sh                          # Interactive setup
    ./tools/dcc-setup.sh --app blender            # Setup Blender only
    ./tools/dcc-setup.sh --app houdini --version 20.5
    ./tools/dcc-setup.sh --dry-run                # Preview changes
    ./tools/dcc-setup.sh --backup --app blender   # Backup then setup
    ./tools/dcc-setup.sh --list                   # List versions
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --app)
                APP="$2"
                shift 2
                ;;
            --app=*)
                APP="${1#*=}"
                shift
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --version=*)
                VERSION="${1#*=}"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --backup)
                DO_BACKUP="true"
                shift
                ;;
            --restore)
                DO_RESTORE="true"
                shift
                ;;
            --list)
                LIST_ONLY="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate app name if provided
    if [[ -n "$APP" ]]; then
        case "$APP" in
            blender|houdini) ;;
            *)
                log_error "Unknown app: $APP"
                log_info "Supported apps: blender, houdini"
                exit 1
                ;;
        esac
    fi
}

# Print DCC setup banner
print_dcc_banner() {
    # Extended colors for gradient effect
    local C1 C2 C3 C4 C5 C6
    if [[ -t 1 ]]; then
        C1='\033[38;5;208m'  # Orange
        C2='\033[38;5;214m'  # Light orange
        C3='\033[38;5;220m'  # Yellow
        C4='\033[38;5;226m'  # Bright yellow
        C5='\033[38;5;190m'  # Yellow-green
        C6='\033[38;5;118m'  # Green
    else
        C1='' C2='' C3='' C4='' C5='' C6=''
    fi

    echo ""
    echo -e "${BOLD}${C1}   ██████╗  ██████╗ ██████╗    ███████╗███████╗████████╗██╗   ██╗██████╗${RESET}"
    echo -e "${BOLD}${C2}   ██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗${RESET}"
    echo -e "${BOLD}${C3}   ██║  ██║██║     ██║         ███████╗█████╗     ██║   ██║   ██║██████╔╝${RESET}"
    echo -e "${BOLD}${C4}   ██║  ██║██║     ██║         ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝${RESET}"
    echo -e "${BOLD}${C5}   ██████╔╝╚██████╗╚██████╗    ███████║███████╗   ██║   ╚██████╔╝██║${RESET}"
    echo -e "${BOLD}${C6}   ╚═════╝  ╚═════╝ ╚═════╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝${RESET}"
    echo ""
    echo -e "   ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "   ${C3}${BOLD}Blender & Houdini Config Management${RESET}"
    echo ""
}

# List all detected versions
list_versions() {
    log_step "Detected DCC Applications"

    echo ""
    echo -e "${BOLD}Blender:${RESET}"
    local blender_versions
    blender_versions="$(find_blender_versions)"
    if [[ -n "$blender_versions" ]]; then
        for ver in $blender_versions; do
            local config_path
            config_path="$(get_blender_config_path "$ver")"
            if [[ -d "$config_path" ]]; then
                echo "  $ver (config exists: $config_path)"
            else
                echo "  $ver (no config directory)"
            fi
        done
    else
        echo "  No versions found"
    fi

    echo ""
    echo -e "${BOLD}Houdini:${RESET}"
    local houdini_versions
    houdini_versions="$(find_houdini_versions)"
    if [[ -n "$houdini_versions" ]]; then
        for ver in $houdini_versions; do
            local config_path
            config_path="$(get_houdini_config_path "$ver")"
            if [[ -d "$config_path" ]]; then
                echo "  $ver (config exists: $config_path)"
            else
                echo "  $ver (no config directory)"
            fi
        done
    else
        echo "  No versions found"
    fi
    echo ""
}

# Setup Blender
setup_blender() {
    local versions=()

    print_header "Blender Setup"

    # Find or use specified version
    if [[ -n "$VERSION" ]]; then
        versions=("$VERSION")
    else
        local found_versions
        found_versions="$(find_blender_versions)"
        if [[ -z "$found_versions" ]]; then
            log_warn "No Blender versions detected"
            log_info "Install Blender first, or specify a version with --version"
            return 0
        fi
        # shellcheck disable=SC2206
        versions=($found_versions)
        select_versions "Blender" "${versions[@]}"
        # shellcheck disable=SC2206
        versions=($REPLY)
    fi

    log_info "Setting up Blender for versions: ${versions[*]}"

    local blender_dir="$DCC_SCRIPT_DIR/blender"

    for ver in "${versions[@]}"; do
        log_step "Configuring Blender $ver"

        local config_path
        config_path="$(get_blender_config_path "$ver")"

        # Backup if requested
        if [[ "$DO_BACKUP" == "true" ]]; then
            backup_dcc_config "blender" "$ver"
        fi

        # Create config directory if it doesn't exist
        if [[ ! -d "$config_path" ]]; then
            log_substep "Creating config directory: $config_path"
            if ! is_dry_run; then
                mkdir -p "$config_path"
            fi
        fi

        # Source Blender installer
        if [[ -f "$blender_dir/install.sh" ]]; then
            source "$blender_dir/install.sh"
            install_blender_config "$ver"
        else
            log_warn "Blender installer not found: $blender_dir/install.sh"
        fi
    done

    log_success "Blender setup complete"
}

# Setup Houdini
setup_houdini() {
    local versions=()

    print_header "Houdini Setup"

    # Find or use specified version
    if [[ -n "$VERSION" ]]; then
        versions=("$VERSION")
    else
        local found_versions
        found_versions="$(find_houdini_versions)"
        if [[ -z "$found_versions" ]]; then
            log_warn "No Houdini versions detected"
            log_info "Install Houdini first, or specify a version with --version"
            return 0
        fi
        # shellcheck disable=SC2206
        versions=($found_versions)
        select_versions "Houdini" "${versions[@]}"
        # shellcheck disable=SC2206
        versions=($REPLY)
    fi

    log_info "Setting up Houdini for versions: ${versions[*]}"

    local houdini_dir="$DCC_SCRIPT_DIR/houdini"

    for ver in "${versions[@]}"; do
        log_step "Configuring Houdini $ver"

        local config_path
        config_path="$(get_houdini_config_path "$ver")"

        # Backup if requested
        if [[ "$DO_BACKUP" == "true" ]]; then
            backup_dcc_config "houdini" "$ver"
        fi

        # Create config directory if it doesn't exist
        if [[ ! -d "$config_path" ]]; then
            log_substep "Creating config directory: $config_path"
            if ! is_dry_run; then
                mkdir -p "$config_path"
            fi
        fi

        # Source Houdini installer
        if [[ -f "$houdini_dir/install.sh" ]]; then
            source "$houdini_dir/install.sh"
            install_houdini_config "$ver"
        else
            log_warn "Houdini installer not found: $houdini_dir/install.sh"
        fi
    done

    log_success "Houdini setup complete"
}

# Restore from backup
restore_configs() {
    print_header "Restore from Backup"

    # Find available backups
    local backup_base="$HOME/.dcc_backup"
    if [[ ! -d "$backup_base" ]]; then
        log_error "No backups found in $backup_base"
        exit 1
    fi

    local backups=()
    for dir in "$backup_base"/*/; do
        if [[ -d "$dir" ]]; then
            backups+=("$(basename "$dir")")
        fi
    done

    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "No backups found"
        exit 1
    fi

    echo "Available backups:"
    for i in "${!backups[@]}"; do
        echo "  $((i+1)). ${backups[$i]}"
    done

    local selection
    read -r -p "Select backup number (or press Enter for latest): " selection

    local backup_dir
    if [[ -z "$selection" ]]; then
        backup_dir="$backup_base/${backups[-1]}"
    else
        backup_dir="$backup_base/${backups[$((selection-1))]}"
    fi

    log_info "Restoring from: $backup_dir"

    # Restore based on app filter
    if [[ -z "$APP" ]] || [[ "$APP" == "blender" ]]; then
        if [[ -d "$backup_dir/blender" ]]; then
            for ver_dir in "$backup_dir/blender"/*/; do
                if [[ -d "$ver_dir" ]]; then
                    local ver
                    ver="$(basename "$ver_dir")"
                    restore_dcc_config "blender" "$ver" "" "$backup_dir"
                fi
            done
        fi
    fi

    if [[ -z "$APP" ]] || [[ "$APP" == "houdini" ]]; then
        if [[ -d "$backup_dir/houdini" ]]; then
            for ver_dir in "$backup_dir/houdini"/*/; do
                if [[ -d "$ver_dir" ]]; then
                    local ver
                    ver="$(basename "$ver_dir")"
                    restore_dcc_config "houdini" "$ver" "" "$backup_dir"
                fi
            done
        fi
    fi

    log_success "Restore complete"
}

# Main function - can be called directly or sourced
dcc_setup() {
    # Show banner
    print_dcc_banner

    # Detect OS
    local os
    os="$(detect_os)"
    log_info "Operating System: $os"

    # Show dry-run notice
    if is_dry_run; then
        echo ""
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Handle restore mode
    if [[ "$DO_RESTORE" == "true" ]]; then
        restore_configs
        return 0
    fi

    # Handle list mode
    if [[ "$LIST_ONLY" == "true" ]]; then
        list_versions
        return 0
    fi

    # Run setup based on app filter
    if [[ -z "$APP" ]]; then
        # Interactive: ask which apps to set up
        echo ""
        if yes_no "Set up Blender configs?" "y"; then
            setup_blender
        fi
        echo ""
        if yes_no "Set up Houdini configs?" "y"; then
            setup_houdini
        fi
    else
        case "$APP" in
            blender)
                setup_blender
                ;;
            houdini)
                setup_houdini
                ;;
        esac
    fi

    # Done
    echo ""
    print_header "DCC Setup Complete"

    if is_dry_run; then
        log_info "This was a dry run. Run without --dry-run to apply changes."
    else
        log_success "DCC application configs have been set up!"
        log_info "Restart your DCC applications for changes to take effect."
    fi
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    dcc_setup
fi
