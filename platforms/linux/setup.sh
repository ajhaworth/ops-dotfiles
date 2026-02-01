#!/usr/bin/env bash
# linux/setup.sh - Linux setup
#
# This script coordinates Linux setup including dotfiles and package management.

linux_setup() {
    print_header "Linux Setup"

    # Source Linux-specific modules
    source "$SCRIPT_DIR/platforms/linux/dotfiles.sh"
    source "$SCRIPT_DIR/platforms/linux/packages.sh"

    # Packages
    if [[ "${PROFILE_PACKAGES:-false}" == "true" ]]; then
        setup_packages
    else
        log_info "Skipping packages (disabled in profile)"
    fi

    # Dotfiles
    if [[ "${PROFILE_DOTFILES:-true}" == "true" ]]; then
        setup_dotfiles
    else
        log_info "Skipping dotfiles (disabled in profile)"
    fi

    log_success "Linux setup complete"
}
