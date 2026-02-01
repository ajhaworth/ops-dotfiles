#!/usr/bin/env bash
# dcc-common.sh - DCC-specific utilities for Blender and Houdini config management

# Get the DCC directory (where this script lives)
get_dcc_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# -----------------------------------------------------------------------------
# Platform-specific config paths
# -----------------------------------------------------------------------------

# Get Blender config base path for the current OS
# Usage: get_blender_config_base
# Returns: Base path without version (e.g., ~/Library/Application Support/Blender)
get_blender_config_base() {
    local os="${1:-$(detect_os)}"

    case "$os" in
        macos)
            echo "$HOME/Library/Application Support/Blender"
            ;;
        linux)
            echo "$HOME/.config/blender"
            ;;
        windows)
            echo "$APPDATA/Blender Foundation/Blender"
            ;;
        *)
            log_error "Unsupported OS for Blender: $os"
            return 1
            ;;
    esac
}

# Get Houdini config base path pattern for the current OS
# Usage: get_houdini_config_base
# Returns: Base path pattern (e.g., ~/houdini for ~/houdini20.5)
get_houdini_config_base() {
    # Houdini uses the same path pattern on all platforms
    echo "$HOME/houdini"
}

# Get full Blender config path for a specific version
# Usage: get_blender_config_path "4.2"
get_blender_config_path() {
    local version="$1"
    local base
    base="$(get_blender_config_base)"
    echo "$base/$version"
}

# Get full Houdini config path for a specific version
# Usage: get_houdini_config_path "20.5"
get_houdini_config_path() {
    local version="$1"
    local base
    base="$(get_houdini_config_base)"
    echo "${base}${version}"
}

# -----------------------------------------------------------------------------
# Version Detection
# -----------------------------------------------------------------------------

# Find installed Blender versions
# Usage: find_blender_versions
# Returns: Space-separated list of installed versions (e.g., "4.0 4.1 4.2")
find_blender_versions() {
    local os="${1:-$(detect_os)}"
    local versions=()
    local config_base
    config_base="$(get_blender_config_base "$os")"

    # Check for existing config directories (indicates version was used)
    if [[ -d "$config_base" ]]; then
        for dir in "$config_base"/*/; do
            if [[ -d "$dir" ]]; then
                local version
                version="$(basename "$dir")"
                # Validate it looks like a version number
                if [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
                    versions+=("$version")
                fi
            fi
        done
    fi

    # Helper to check if version already in array
    version_exists() {
        local check="$1"
        local v
        for v in "${versions[@]+"${versions[@]}"}"; do
            [[ "$v" == "$check" ]] && return 0
        done
        return 1
    }

    # Also check for installed Blender applications
    case "$os" in
        macos)
            # Check /Applications for Blender.app
            if [[ -d "/Applications/Blender.app" ]]; then
                local app_version
                app_version="$(get_blender_app_version_macos "/Applications/Blender.app")"
                if [[ -n "$app_version" ]] && ! version_exists "$app_version"; then
                    versions+=("$app_version")
                fi
            fi
            # Check homebrew cask location
            for app in /opt/homebrew/Caskroom/blender/*/Blender.app /usr/local/Caskroom/blender/*/Blender.app; do
                if [[ -d "$app" ]]; then
                    local app_version
                    app_version="$(get_blender_app_version_macos "$app")"
                    if [[ -n "$app_version" ]] && ! version_exists "$app_version"; then
                        versions+=("$app_version")
                    fi
                fi
            done
            ;;
        linux)
            # Check common Linux install locations
            for blender_bin in /usr/bin/blender /usr/local/bin/blender /opt/blender*/blender "$HOME/blender*/blender"; do
                if [[ -x "$blender_bin" ]]; then
                    local app_version
                    app_version="$("$blender_bin" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
                    if [[ -n "$app_version" ]] && ! version_exists "$app_version"; then
                        versions+=("$app_version")
                    fi
                fi
            done
            ;;
    esac

    # Sort versions
    printf '%s\n' "${versions[@]}" | sort -V | tr '\n' ' ' | sed 's/ $//'
}

# Get Blender version from macOS .app bundle
get_blender_app_version_macos() {
    local app_path="$1"
    local plist="$app_path/Contents/Info.plist"

    if [[ -f "$plist" ]]; then
        # Extract version from CFBundleShortVersionString
        local full_version
        full_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null)"
        # Return major.minor only
        echo "$full_version" | grep -oE '^[0-9]+\.[0-9]+'
    fi
}

# Find installed Houdini versions
# Usage: find_houdini_versions
# Returns: Space-separated list of installed versions (e.g., "19.5 20.0 20.5")
find_houdini_versions() {
    local os="${1:-$(detect_os)}"
    local versions=()
    local base
    base="$(get_houdini_config_base)"

    # Helper to check if version already in array
    houdini_version_exists() {
        local check="$1"
        local v
        for v in "${versions[@]+"${versions[@]}"}"; do
            [[ "$v" == "$check" ]] && return 0
        done
        return 1
    }

    # Check for existing config directories
    for dir in "$base"*/; do
        if [[ -d "$dir" ]]; then
            local dirname
            dirname="$(basename "$dir")"
            # Extract version from houdiniXX.X format
            if [[ "$dirname" =~ ^houdini([0-9]+\.[0-9]+)$ ]]; then
                versions+=("${BASH_REMATCH[1]}")
            fi
        fi
    done

    # Also check for installed Houdini applications
    case "$os" in
        macos)
            # Check /Applications for Houdini
            for app in "/Applications/Houdini/Houdini"*; do
                if [[ -d "$app" ]]; then
                    local app_name
                    app_name="$(basename "$app")"
                    if [[ "$app_name" =~ ^Houdini[[:space:]]+([0-9]+\.[0-9]+) ]]; then
                        local ver="${BASH_REMATCH[1]}"
                        if ! houdini_version_exists "$ver"; then
                            versions+=("$ver")
                        fi
                    fi
                fi
            done
            ;;
        linux)
            # Check /opt for Houdini installations
            for hfs in /opt/hfs* /opt/sidefx/houdini*; do
                if [[ -d "$hfs" ]]; then
                    local dirname
                    dirname="$(basename "$hfs")"
                    if [[ "$dirname" =~ ([0-9]+\.[0-9]+) ]]; then
                        local ver="${BASH_REMATCH[1]}"
                        if ! houdini_version_exists "$ver"; then
                            versions+=("$ver")
                        fi
                    fi
                fi
            done
            ;;
    esac

    # Sort versions (handle empty array)
    if [[ ${#versions[@]} -gt 0 ]]; then
        printf '%s\n' "${versions[@]}" | sort -V | tr '\n' ' ' | sed 's/ $//'
    fi
}

# -----------------------------------------------------------------------------
# DCC Backup Management
# -----------------------------------------------------------------------------

# Default DCC backup directory
DCC_BACKUP_DIR="${DCC_BACKUP_DIR:-$HOME/.dcc_backup/$(date +%Y%m%d_%H%M%S)}"

# Backup a DCC config directory
# Usage: backup_dcc_config "blender" "4.2" [subdirectory]
backup_dcc_config() {
    local app="$1"
    local version="$2"
    local subdir="${3:-}"

    local config_path
    case "$app" in
        blender)
            config_path="$(get_blender_config_path "$version")"
            ;;
        houdini)
            config_path="$(get_houdini_config_path "$version")"
            ;;
        *)
            log_error "Unknown DCC app: $app"
            return 1
            ;;
    esac

    if [[ -n "$subdir" ]]; then
        config_path="$config_path/$subdir"
    fi

    if [[ ! -e "$config_path" ]]; then
        log_substep "Nothing to backup: $config_path"
        return 0
    fi

    local backup_path="$DCC_BACKUP_DIR/$app/$version"
    if [[ -n "$subdir" ]]; then
        backup_path="$backup_path/$subdir"
    fi

    log_substep "Backing up: $config_path -> $backup_path"

    if is_dry_run; then
        log_dry "mkdir -p \"$(dirname "$backup_path")\""
        log_dry "cp -R \"$config_path\" \"$backup_path\""
    else
        mkdir -p "$(dirname "$backup_path")"
        cp -R "$config_path" "$backup_path"
    fi
}

# Restore a DCC config from backup
# Usage: restore_dcc_config "blender" "4.2" [subdirectory]
restore_dcc_config() {
    local app="$1"
    local version="$2"
    local subdir="${3:-}"
    local backup_dir="${4:-}"

    # If no backup dir specified, find the most recent
    if [[ -z "$backup_dir" ]]; then
        backup_dir="$(find "$HOME/.dcc_backup" -maxdepth 1 -type d -name '20*' | sort -r | head -1)"
    fi

    if [[ -z "$backup_dir" ]] || [[ ! -d "$backup_dir" ]]; then
        log_error "No backup found to restore"
        return 1
    fi

    local backup_path="$backup_dir/$app/$version"
    if [[ -n "$subdir" ]]; then
        backup_path="$backup_path/$subdir"
    fi

    if [[ ! -e "$backup_path" ]]; then
        log_error "Backup not found: $backup_path"
        return 1
    fi

    local config_path
    case "$app" in
        blender)
            config_path="$(get_blender_config_path "$version")"
            ;;
        houdini)
            config_path="$(get_houdini_config_path "$version")"
            ;;
        *)
            log_error "Unknown DCC app: $app"
            return 1
            ;;
    esac

    if [[ -n "$subdir" ]]; then
        config_path="$config_path/$subdir"
    fi

    log_substep "Restoring: $backup_path -> $config_path"

    if is_dry_run; then
        log_dry "rm -rf \"$config_path\""
        log_dry "cp -R \"$backup_path\" \"$config_path\""
    else
        rm -rf "$config_path"
        cp -R "$backup_path" "$config_path"
    fi
}

# -----------------------------------------------------------------------------
# Symlink Helpers for DCC configs
# -----------------------------------------------------------------------------

# Create a symlink for DCC config, with DCC-specific backup logic
# Usage: dcc_symlink source destination
dcc_symlink() {
    local source="$1"
    local destination="$2"

    # Expand ~ in paths
    source="${source/#\~/$HOME}"
    destination="${destination/#\~/$HOME}"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_warn "Source does not exist, skipping: $source"
        return 0
    fi

    # Get absolute path of source
    source="$(cd "$(dirname "$source")" && pwd)/$(basename "$source")"

    # Create parent directory if needed
    local dest_dir
    dest_dir="$(dirname "$destination")"
    if [[ ! -d "$dest_dir" ]]; then
        log_substep "Creating directory: $dest_dir"
        if ! is_dry_run; then
            mkdir -p "$dest_dir"
        fi
    fi

    # Handle existing file/symlink at destination
    if [[ -e "$destination" ]] || [[ -L "$destination" ]]; then
        # Check if already correctly linked
        if [[ -L "$destination" ]]; then
            local current_target
            current_target="$(readlink "$destination")"
            if [[ "$current_target" == "$source" ]]; then
                log_substep "Already linked: $destination"
                return 0
            fi
        fi

        # For DCC configs, we don't auto-backup by default
        # The caller should use backup_dcc_config if needed
        log_substep "Removing existing: $destination"
        if ! is_dry_run; then
            rm -rf "$destination"
        fi
    fi

    # Create the symlink
    log_substep "Linking: $destination -> $source"
    if is_dry_run; then
        log_dry "ln -sf \"$source\" \"$destination\""
    else
        ln -sf "$source" "$destination"
    fi
}

# Process a DCC manifest file
# Format: source|destination (paths relative to DCC app directory and config directory)
# Usage: process_dcc_manifest manifest_file app_dir config_dir
process_dcc_manifest() {
    local manifest="$1"
    local app_dir="$2"
    local config_dir="$3"

    if [[ ! -f "$manifest" ]]; then
        log_error "Manifest not found: $manifest"
        return 1
    fi

    while IFS='|' read -r source destination || [[ -n "$source" ]]; do
        # Skip empty lines and comments
        [[ -z "$source" ]] && continue
        [[ "$source" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        source="$(echo "$source" | xargs)"
        destination="$(echo "$destination" | xargs)"

        # Make paths absolute
        local full_source="$app_dir/$source"
        local full_dest="$config_dir/$destination"

        # Create symlink
        dcc_symlink "$full_source" "$full_dest"
    done < "$manifest"
}

# -----------------------------------------------------------------------------
# User Interaction
# -----------------------------------------------------------------------------

# Prompt user to select versions from a list
# Usage: select_versions "app_name" version1 version2 version3
# Returns: Selected versions in $REPLY as space-separated string
select_versions() {
    local app_name="$1"
    shift
    local versions=("$@")

    if [[ ${#versions[@]} -eq 0 ]]; then
        log_warn "No $app_name versions found"
        REPLY=""
        return 1
    fi

    if [[ ${#versions[@]} -eq 1 ]]; then
        log_info "Found $app_name version: ${versions[0]}"
        REPLY="${versions[0]}"
        return 0
    fi

    echo ""
    log_step "Select $app_name version(s) to configure"
    echo "Found versions: ${versions[*]}"
    echo ""
    echo "Enter version numbers separated by spaces, or 'all' for all versions:"

    read -r -p "> " response

    if [[ "$response" == "all" ]] || [[ -z "$response" ]]; then
        REPLY="${versions[*]}"
    else
        REPLY="$response"
    fi
}
