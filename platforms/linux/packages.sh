#!/usr/bin/env bash
# platforms/linux/packages.sh - Linux package management

# Detect the package manager
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Setup packages
setup_packages() {
    print_header "Package Installation"

    local pkg_manager
    pkg_manager=$(detect_package_manager)

    if [[ "$pkg_manager" == "unknown" ]]; then
        log_warn "Unknown package manager - skipping package installation"
        return 0
    fi

    log_info "Detected package manager: $pkg_manager"

    # Update package lists
    update_packages "$pkg_manager"

    # Install packages
    install_packages "$pkg_manager"

    log_success "Package installation complete"
}

# Update package lists
update_packages() {
    local pkg_manager="$1"
    log_step "Updating package lists"

    if is_dry_run; then
        log_dry "sudo $pkg_manager update"
        return 0
    fi

    case "$pkg_manager" in
        apt)
            sudo apt-get update -qq
            ;;
        dnf|yum)
            sudo "$pkg_manager" check-update -q || true
            ;;
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        zypper)
            sudo zypper refresh -q
            ;;
    esac

    log_success "Package lists updated"
}

# Install packages from category files
install_packages() {
    local pkg_manager="$1"
    local packages_dir="$SCRIPT_DIR/config/packages/linux/$pkg_manager"

    if [[ ! -d "$packages_dir" ]]; then
        log_warn "No package lists found for $pkg_manager"
        return 0
    fi

    log_step "Installing packages"

    # Collect all packages to install
    local packages=()

    for category_file in "$packages_dir"/*.txt; do
        [[ -f "$category_file" ]] || continue

        local category
        category=$(basename "$category_file" .txt)

        # Check if category is enabled in profile
        local var_name
        var_name="PACKAGES_$(echo "$category" | tr '[:lower:]-' '[:upper:]_')"

        if [[ "${!var_name:-true}" != "true" ]]; then
            log_substep "Skipping $category (disabled in profile)"
            continue
        fi

        log_substep "Reading $category packages"

        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*# ]] && continue

            # Extract package name (remove inline comments)
            local pkg
            pkg=$(echo "$line" | sed 's/#.*//' | xargs)
            [[ -n "$pkg" ]] && packages+=("$pkg")
        done < "$category_file"
    done

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "No packages to install"
        return 0
    fi

    log_info "Installing ${#packages[@]} packages..."

    if is_dry_run; then
        for pkg in "${packages[@]}"; do
            log_dry "install $pkg"
        done
        return 0
    fi

    # Install packages
    case "$pkg_manager" in
        apt)
            sudo apt-get install -y "${packages[@]}"
            ;;
        dnf|yum)
            sudo "$pkg_manager" install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm --needed "${packages[@]}"
            ;;
        zypper)
            sudo zypper install -y "${packages[@]}"
            ;;
    esac
}

# Check package status
check_packages() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    if [[ "$pkg_manager" == "unknown" ]]; then
        log_warn "Unknown package manager"
        return 0
    fi

    local packages_dir="$SCRIPT_DIR/config/packages/linux/$pkg_manager"

    if [[ ! -d "$packages_dir" ]]; then
        log_warn "No package lists found for $pkg_manager"
        return 0
    fi

    local installed=0
    local missing=0

    for category_file in "$packages_dir"/*.txt; do
        [[ -f "$category_file" ]] || continue

        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" ]] && continue
            [[ "$line" =~ ^[[:space:]]*# ]] && continue

            local pkg
            pkg=$(echo "$line" | sed 's/#.*//' | xargs)
            [[ -z "$pkg" ]] && continue

            if is_package_installed "$pkg_manager" "$pkg"; then
                echo -e "  ${GREEN}✓${RESET} $pkg"
                ((installed++))
            else
                echo -e "  ${RED}✗${RESET} $pkg"
                ((missing++))
            fi
        done < "$category_file"
    done

    echo ""
    echo -e "  ${GREEN}$installed installed${RESET}"
    if [[ $missing -gt 0 ]]; then
        echo -e "  ${RED}$missing missing${RESET}"
    fi
}

# Check if a package is installed
is_package_installed() {
    local pkg_manager="$1"
    local pkg="$2"

    case "$pkg_manager" in
        apt)
            dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$pkg" &>/dev/null
            ;;
        pacman)
            pacman -Q "$pkg" &>/dev/null
            ;;
        zypper)
            rpm -q "$pkg" &>/dev/null
            ;;
    esac
}
