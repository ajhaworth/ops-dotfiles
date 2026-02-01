#!/usr/bin/env bash
# houdini/install.sh - Houdini configuration installer
#
# This script is sourced by dcc-setup.sh and provides the install_houdini_config function.
# It symlinks managed Houdini configs to the user's Houdini config directory.

# Get the Houdini config directory in this repo
HOUDINI_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Houdini subdirectories to manage
# Each directory is linked individually so users can add their own files
HOUDINI_MANAGED_DIRS=(
    "desktop"    # UI layouts (.desk files)
    "toolbar"    # Shelf tools
    "scripts"    # Python scripts
    "otls"       # HDAs (Houdini Digital Assets)
    "presets"    # Parameter presets
    "packages"   # Package definitions
)

# Install Houdini configuration for a specific version
# Usage: install_houdini_config "20.5"
install_houdini_config() {
    local version="$1"
    local config_path
    config_path="$(get_houdini_config_path "$version")"

    log_info "Installing Houdini $version config to: $config_path"

    # Ensure config directory exists
    if [[ ! -d "$config_path" ]]; then
        log_substep "Creating config directory"
        if ! is_dry_run; then
            mkdir -p "$config_path"
        fi
    fi

    # Process each managed directory
    for dir in "${HOUDINI_MANAGED_DIRS[@]}"; do
        install_houdini_dir "$version" "$config_path" "$dir"
    done
}

# Install a specific Houdini directory's contents
# Usage: install_houdini_dir "20.5" "/path/to/houdini20.5" "desktop"
install_houdini_dir() {
    local version="$1"
    local config_path="$2"
    local dir_name="$3"

    local repo_dir="$HOUDINI_REPO_DIR/$dir_name"
    local dest_dir="$config_path/$dir_name"

    # Check if we have files to install
    if [[ ! -d "$repo_dir" ]]; then
        return 0
    fi

    # Check if repo dir has any files
    local has_files=false
    for item in "$repo_dir"/*; do
        if [[ -e "$item" ]]; then
            has_files=true
            break
        fi
    done

    if [[ "$has_files" == "false" ]]; then
        return 0
    fi

    log_substep "Setting up $dir_name/"

    # Create destination directory if needed
    if [[ ! -d "$dest_dir" ]]; then
        if ! is_dry_run; then
            mkdir -p "$dest_dir"
        fi
    fi

    # Link individual files/directories (not the whole directory)
    # This allows users to have their own additions
    for item in "$repo_dir"/*; do
        if [[ -e "$item" ]]; then
            local item_name
            item_name="$(basename "$item")"

            # Skip hidden files and READMEs
            [[ "$item_name" == .* ]] && continue
            [[ "$item_name" == "README"* ]] && continue

            dcc_symlink "$item" "$dest_dir/$item_name"
        fi
    done
}

# Check Houdini config status
# Usage: check_houdini_config "20.5"
check_houdini_config() {
    local version="$1"
    local config_path
    config_path="$(get_houdini_config_path "$version")"

    echo -e "${BOLD}Houdini $version:${RESET} $config_path"

    if [[ ! -d "$config_path" ]]; then
        echo "  Config directory does not exist"
        return 1
    fi

    # Check for managed symlinks in each directory
    local found_managed=false

    for dir in "${HOUDINI_MANAGED_DIRS[@]}"; do
        local full_path="$config_path/$dir"
        if [[ -d "$full_path" ]]; then
            for item in "$full_path"/*; do
                if [[ -L "$item" ]]; then
                    local target
                    target="$(readlink "$item")"
                    if [[ "$target" == *"setup-os"* ]]; then
                        found_managed=true
                        echo -e "  ${GREEN}[linked]${RESET} $dir/$(basename "$item")"
                    fi
                fi
            done
        fi
    done

    if [[ "$found_managed" == "false" ]]; then
        echo "  No managed configs found"
    fi
}

# Unlink managed Houdini configs
# Usage: unlink_houdini_config "20.5"
unlink_houdini_config() {
    local version="$1"
    local config_path
    config_path="$(get_houdini_config_path "$version")"

    if [[ ! -d "$config_path" ]]; then
        log_warn "Config directory does not exist: $config_path"
        return 0
    fi

    log_info "Unlinking managed Houdini $version configs"

    for dir in "${HOUDINI_MANAGED_DIRS[@]}"; do
        local full_path="$config_path/$dir"
        if [[ -d "$full_path" ]]; then
            for item in "$full_path"/*; do
                if [[ -L "$item" ]]; then
                    local target
                    target="$(readlink "$item")"
                    if [[ "$target" == *"setup-os"* ]]; then
                        log_substep "Removing: $item"
                        if ! is_dry_run; then
                            rm "$item"
                        fi
                    fi
                fi
            done
        fi
    done
}
