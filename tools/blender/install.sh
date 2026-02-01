#!/usr/bin/env bash
# blender/install.sh - Blender configuration installer
#
# This script is sourced by dcc-setup.sh and provides the install_blender_config function.
# It symlinks managed Blender configs to the user's Blender config directory.

# Get the Blender config directory in this repo
BLENDER_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install Blender configuration for a specific version
# Usage: install_blender_config "4.2"
install_blender_config() {
    local version="$1"
    local config_path
    config_path="$(get_blender_config_path "$version")"

    log_info "Installing Blender $version config to: $config_path"

    # Ensure config directory exists
    if [[ ! -d "$config_path" ]]; then
        log_substep "Creating config directory"
        if ! is_dry_run; then
            mkdir -p "$config_path"
        fi
    fi

    # Link config directory (preferences, bookmarks, etc.)
    install_blender_config_dir "$version" "$config_path"

    # Link scripts directory (addons, presets, startup)
    install_blender_scripts_dir "$version" "$config_path"
}

# Install Blender config/ directory contents
install_blender_config_dir() {
    local version="$1"
    local config_path="$2"
    local repo_config_dir="$BLENDER_REPO_DIR/config"

    # Check if we have config files to install
    if [[ ! -d "$repo_config_dir" ]]; then
        log_substep "No config directory in repo, skipping"
        return 0
    fi

    local dest_config_dir="$config_path/config"

    # Create config directory if needed
    if [[ ! -d "$dest_config_dir" ]]; then
        log_substep "Creating: $dest_config_dir"
        if ! is_dry_run; then
            mkdir -p "$dest_config_dir"
        fi
    fi

    # Link individual config files (so user can have local additions)
    for file in "$repo_config_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename
            filename="$(basename "$file")"
            dcc_symlink "$file" "$dest_config_dir/$filename"
        fi
    done
}

# Install Blender scripts/ directory contents
install_blender_scripts_dir() {
    local version="$1"
    local config_path="$2"
    local repo_scripts_dir="$BLENDER_REPO_DIR/scripts"

    # Check if we have scripts to install
    if [[ ! -d "$repo_scripts_dir" ]]; then
        log_substep "No scripts directory in repo, skipping"
        return 0
    fi

    local dest_scripts_dir="$config_path/scripts"

    # Create scripts directory if needed
    if [[ ! -d "$dest_scripts_dir" ]]; then
        log_substep "Creating: $dest_scripts_dir"
        if ! is_dry_run; then
            mkdir -p "$dest_scripts_dir"
        fi
    fi

    # Link addons directory
    if [[ -d "$repo_scripts_dir/addons" ]]; then
        local dest_addons="$dest_scripts_dir/addons"
        if [[ ! -d "$dest_addons" ]]; then
            if ! is_dry_run; then
                mkdir -p "$dest_addons"
            fi
        fi

        # Link individual addons (so user can have their own addons too)
        for addon in "$repo_scripts_dir/addons"/*; do
            if [[ -e "$addon" ]]; then
                local addon_name
                addon_name="$(basename "$addon")"
                dcc_symlink "$addon" "$dest_addons/$addon_name"
            fi
        done
    fi

    # Link presets directory
    if [[ -d "$repo_scripts_dir/presets" ]]; then
        local dest_presets="$dest_scripts_dir/presets"
        if [[ ! -d "$dest_presets" ]]; then
            if ! is_dry_run; then
                mkdir -p "$dest_presets"
            fi
        fi

        # Link preset categories (render, keyconfig, etc.)
        for preset_category in "$repo_scripts_dir/presets"/*; do
            if [[ -d "$preset_category" ]]; then
                local category_name
                category_name="$(basename "$preset_category")"
                local dest_category="$dest_presets/$category_name"

                if [[ ! -d "$dest_category" ]]; then
                    if ! is_dry_run; then
                        mkdir -p "$dest_category"
                    fi
                fi

                # Link individual preset files
                for preset_file in "$preset_category"/*; do
                    if [[ -f "$preset_file" ]]; then
                        local preset_name
                        preset_name="$(basename "$preset_file")"
                        dcc_symlink "$preset_file" "$dest_category/$preset_name"
                    fi
                done
            fi
        done
    fi

    # Link startup directory
    if [[ -d "$repo_scripts_dir/startup" ]]; then
        local dest_startup="$dest_scripts_dir/startup"
        if [[ ! -d "$dest_startup" ]]; then
            if ! is_dry_run; then
                mkdir -p "$dest_startup"
            fi
        fi

        # Link startup scripts
        for script in "$repo_scripts_dir/startup"/*; do
            if [[ -f "$script" ]]; then
                local script_name
                script_name="$(basename "$script")"
                dcc_symlink "$script" "$dest_startup/$script_name"
            fi
        done
    fi
}

# Check Blender config status
# Usage: check_blender_config "4.2"
check_blender_config() {
    local version="$1"
    local config_path
    config_path="$(get_blender_config_path "$version")"

    echo -e "${BOLD}Blender $version:${RESET} $config_path"

    if [[ ! -d "$config_path" ]]; then
        echo "  Config directory does not exist"
        return 1
    fi

    # Check for managed symlinks
    local found_managed=false

    for check_dir in "config" "scripts/addons" "scripts/presets" "scripts/startup"; do
        local full_path="$config_path/$check_dir"
        if [[ -d "$full_path" ]]; then
            for item in "$full_path"/*; do
                if [[ -L "$item" ]]; then
                    local target
                    target="$(readlink "$item")"
                    if [[ "$target" == *"setup-os"* ]]; then
                        found_managed=true
                        echo -e "  ${GREEN}[linked]${RESET} $(basename "$item") -> $target"
                    fi
                fi
            done
        fi
    done

    if [[ "$found_managed" == "false" ]]; then
        echo "  No managed configs found"
    fi
}
