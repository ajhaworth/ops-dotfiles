#!/usr/bin/env bash
# packages.sh - Package parsing helpers

# Parse a package list file
# Returns packages one per line, skipping comments and empty lines
# Usage: parse_package_list file.txt
parse_package_list() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "Package file not found: $file"
        return 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Remove leading/trailing whitespace
        line="$(echo "$line" | xargs)"

        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Skip comments
        [[ "$line" =~ ^# ]] && continue

        # Handle inline comments (everything after #)
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"

        # Skip if empty after removing comment
        [[ -z "$line" ]] && continue

        echo "$line"
    done < "$file"
}

# Parse MAS (Mac App Store) app list
# Format: ID|Name
# Returns: ID and Name separated by tab
# Usage: parse_mas_list file.txt
parse_mas_list() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "MAS file not found: $file"
        return 1
    fi

    while IFS='|' read -r id name || [[ -n "$id" ]]; do
        # Remove leading/trailing whitespace
        id="$(echo "$id" | xargs)"
        name="$(echo "$name" | xargs)"

        # Skip empty lines
        [[ -z "$id" ]] && continue

        # Skip comments
        [[ "$id" =~ ^# ]] && continue

        # Validate ID is numeric
        if ! [[ "$id" =~ ^[0-9]+$ ]]; then
            log_warn "Invalid MAS ID: $id"
            continue
        fi

        echo -e "$id\t$name"
    done < "$file"
}

# Get packages from a directory of package files
# Usage: get_packages_from_dir directory [file_pattern]
get_packages_from_dir() {
    local dir="$1"
    local pattern="${2:-*.txt}"

    if [[ ! -d "$dir" ]]; then
        log_error "Package directory not found: $dir"
        return 1
    fi

    for file in "$dir"/$pattern; do
        [[ -f "$file" ]] || continue
        parse_package_list "$file"
    done
}

# Check if a package category is enabled for the current profile
# Usage: is_category_enabled category
is_category_enabled() {
    local category="$1"

    # Check if profile has explicitly disabled this category
    local skip_var="SKIP_${category^^}"
    if [[ "${!skip_var:-false}" == "true" ]]; then
        return 1
    fi

    # Check profile-specific settings
    case "$category" in
        media|graphics|gaming)
            [[ "${PROFILE_PERSONAL_APPS:-true}" == "true" ]]
            ;;
        mas)
            [[ "${PROFILE_MAS:-true}" == "true" ]]
            ;;
        *)
            return 0
            ;;
    esac
}

# Get all enabled formulae for the current profile
# Usage: get_enabled_formulae packages_dir
get_enabled_formulae() {
    local packages_dir="$1"
    local formulae_dir="$packages_dir/formulae"

    for file in "$formulae_dir"/*.txt; do
        [[ -f "$file" ]] || continue

        local category
        category="$(basename "$file" .txt)"

        if is_category_enabled "$category"; then
            parse_package_list "$file"
        else
            log_substep "Skipping formulae category: $category"
        fi
    done
}

# Get all enabled casks for the current profile
# Usage: get_enabled_casks packages_dir
get_enabled_casks() {
    local packages_dir="$1"
    local casks_dir="$packages_dir/casks"

    for file in "$casks_dir"/*.txt; do
        [[ -f "$file" ]] || continue

        local category
        category="$(basename "$file" .txt)"

        if is_category_enabled "$category"; then
            parse_package_list "$file"
        else
            log_substep "Skipping cask category: $category"
        fi
    done
}

# Count packages in a directory
# Usage: count_packages dir
count_packages() {
    local dir="$1"
    local count=0

    for file in "$dir"/*.txt; do
        [[ -f "$file" ]] || continue
        local file_count
        file_count=$(parse_package_list "$file" | wc -l | xargs)
        count=$((count + file_count))
    done

    echo "$count"
}

# List package categories in a directory
# Usage: list_categories dir
list_categories() {
    local dir="$1"

    for file in "$dir"/*.txt; do
        [[ -f "$file" ]] || continue
        basename "$file" .txt
    done
}
