#!/usr/bin/env bash
# platforms/macos/homebrew.sh - Homebrew installation and package management

# Homebrew installation URL
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Setup Homebrew
setup_homebrew() {
    print_header "Homebrew Setup"

    # Install Homebrew if not present
    install_homebrew

    # Update Homebrew
    update_homebrew

    # Install packages
    install_formulae
    install_casks

    # Install MAS apps if enabled
    if [[ "$SKIP_MAS" != "true" ]] && [[ "${PROFILE_MAS:-true}" == "true" ]]; then
        install_mas_apps
    else
        log_info "Skipping Mac App Store apps"
    fi

    # Cleanup
    cleanup_homebrew
}

# Install Homebrew
install_homebrew() {
    log_step "Checking Homebrew installation"

    if command_exists brew; then
        log_success "Homebrew already installed"
        eval_brew_shellenv
        return 0
    fi

    log_info "Installing Homebrew..."

    if is_dry_run; then
        log_dry "curl -fsSL $HOMEBREW_INSTALL_URL | bash"
        return 0
    fi

    # Install Homebrew (non-interactive)
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $HOMEBREW_INSTALL_URL)"

    eval_brew_shellenv
    log_success "Homebrew installed"
}

# Evaluate brew shellenv for PATH setup
eval_brew_shellenv() {
    if is_apple_silicon; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

# Update Homebrew
update_homebrew() {
    log_step "Updating Homebrew"

    if is_dry_run; then
        log_dry "brew update"
        return 0
    fi

    brew update
    log_success "Homebrew updated"
}

# Install Homebrew formulae
install_formulae() {
    log_step "Installing Homebrew formulae"

    local packages_dir="$SCRIPT_DIR/config/packages/macos/formulae"
    local formulae=()

    # Collect all enabled formulae
    for file in "$packages_dir"/*.txt; do
        [[ -f "$file" ]] || continue

        local category
        category="$(basename "$file" .txt)"
        local category_upper
        category_upper="$(echo "$category" | tr '[:lower:]-' '[:upper:]_')"
        local category_var="FORMULAE_${category_upper}"

        # Check if category is enabled (default to true if not set)
        if [[ "${!category_var:-true}" == "true" ]]; then
            log_substep "Including category: $category"
            while IFS= read -r package; do
                formulae+=("$package")
            done < <(parse_package_list "$file")
        else
            log_substep "Skipping category: $category"
        fi
    done

    if [[ ${#formulae[@]} -eq 0 ]]; then
        log_warn "No formulae to install"
        return 0
    fi

    log_info "Installing ${#formulae[@]} formulae..."

    if is_dry_run; then
        for formula in "${formulae[@]}"; do
            log_dry "brew install $formula"
        done
        return 0
    fi

    # Install formulae (continue on error)
    for formula in "${formulae[@]}"; do
        if brew list --formula "$formula" &>/dev/null; then
            log_substep "Already installed: $formula"
        else
            log_substep "Installing: $formula"
            brew install "$formula" || log_warn "Failed to install: $formula"
        fi
    done

    log_success "Formulae installation complete"
}

# Install Homebrew casks
install_casks() {
    log_step "Installing Homebrew casks"

    local packages_dir="$SCRIPT_DIR/config/packages/macos/casks"
    local casks=()

    # Collect all enabled casks
    for file in "$packages_dir"/*.txt; do
        [[ -f "$file" ]] || continue

        local category
        category="$(basename "$file" .txt)"
        local category_upper
        category_upper="$(echo "$category" | tr '[:lower:]-' '[:upper:]_')"
        local category_var="CASKS_${category_upper}"

        # Check if category is enabled (default to true if not set)
        if [[ "${!category_var:-true}" == "true" ]]; then
            log_substep "Including category: $category"
            while IFS= read -r package; do
                casks+=("$package")
            done < <(parse_package_list "$file")
        else
            log_substep "Skipping category: $category"
        fi
    done

    if [[ ${#casks[@]} -eq 0 ]]; then
        log_warn "No casks to install"
        return 0
    fi

    log_info "Installing ${#casks[@]} casks..."

    if is_dry_run; then
        for cask in "${casks[@]}"; do
            log_dry "brew install --cask $cask"
        done
        return 0
    fi

    # Install casks (continue on error)
    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            log_substep "Already installed: $cask"
        else
            log_substep "Installing: $cask"
            brew install --cask "$cask" || log_warn "Failed to install: $cask"
        fi
    done

    log_success "Cask installation complete"
}

# Install Mac App Store apps
install_mas_apps() {
    log_step "Installing Mac App Store apps"

    # Install mas CLI if not present
    if ! command_exists mas; then
        log_info "Installing mas CLI..."
        if is_dry_run; then
            log_dry "brew install mas"
        else
            brew install mas
        fi
    fi

    local mas_file="$SCRIPT_DIR/config/packages/macos/mas/apps.txt"

    if [[ ! -f "$mas_file" ]]; then
        log_warn "MAS apps file not found: $mas_file"
        return 0
    fi

    # Note: mas account is deprecated in macOS 12+, so we skip the sign-in check
    # and rely on mas install failing gracefully if not signed in

    # Suppress Spotlight indexing warnings from mas
    export MAS_NO_AUTO_INDEX=1

    # Install apps
    while IFS=$'\t' read -r id name; do
        [[ -z "$id" ]] && continue

        if is_dry_run; then
            log_dry "mas install $id  # $name"
        else
            local mas_output
            if mas_output=$(mas install "$id" 2>&1); then
                if echo "$mas_output" | grep -q "already installed"; then
                    log_substep "Already installed: $name"
                else
                    log_substep "Installed: $name"
                fi
            else
                log_warn "Failed to install: $name"
            fi
        fi
    done < <(parse_mas_list "$mas_file")

    log_success "MAS app installation complete"
}

# Cleanup Homebrew
cleanup_homebrew() {
    log_step "Cleaning up Homebrew"

    if is_dry_run; then
        log_dry "brew cleanup"
        return 0
    fi

    brew cleanup
    log_success "Homebrew cleanup complete"
}
