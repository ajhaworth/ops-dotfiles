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

