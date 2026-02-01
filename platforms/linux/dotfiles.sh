#!/usr/bin/env bash
# platforms/linux/dotfiles.sh - Dotfiles installation for Linux

# Setup dotfiles
setup_dotfiles() {
    print_header "Dotfiles Setup"

    local dotfiles_dir="$SCRIPT_DIR/config/dotfiles"
    local manifest="$dotfiles_dir/manifest.txt"

    if [[ ! -f "$manifest" ]]; then
        log_warn "Dotfiles manifest not found: $manifest"
        return 0
    fi

    log_step "Processing dotfiles manifest"

    # Process the manifest file
    process_manifest "$manifest"

    # Show status
    log_step "Dotfiles status"
    check_manifest "$manifest" || true

    # Create local override files if they don't exist
    create_local_overrides

    log_success "Dotfiles setup complete"
}

# Create local override files for user-specific settings
create_local_overrides() {
    log_step "Checking local override files"

    # Create zshrc.local if needed
    create_zshrc_local

    # Create gitconfig.local if git dotfiles are enabled
    if [[ "${DOTFILES_GIT:-true}" == "true" ]]; then
        create_gitconfig_local
    fi
}

# Create ~/.zshrc.local with template
create_zshrc_local() {
    local file="$HOME/.zshrc.local"

    if [[ -f "$file" ]]; then
        log_substep "Already exists: $file"
        return 0
    fi

    log_substep "Creating: $file"

    if is_dry_run; then
        log_dry "touch $file"
        return 0
    fi

    cat > "$file" << 'EOF'
# ~/.zshrc.local - Machine-specific shell configuration
# This file is sourced by .zshrc and is not tracked by git

# Add your machine-specific aliases and functions here
# Example:
# export PATH="$HOME/custom/bin:$PATH"
# alias myalias='my-command'
EOF
}

# Create ~/.gitconfig.local, prompting for user info if interactive
create_gitconfig_local() {
    local file="$HOME/.gitconfig.local"

    if [[ -f "$file" ]]; then
        log_substep "Already exists: $file"
        return 0
    fi

    log_substep "Creating: $file"

    if is_dry_run; then
        log_dry "Would prompt for git name and email (interactive) or create template"
        return 0
    fi

    # Interactive mode: prompt for git user info
    if [[ -t 0 ]] && [[ "${FORCE:-false}" != "true" ]]; then
        log_info "Setting up git configuration..."
        echo ""

        prompt_input "Git user name" ""
        local git_name="$REPLY"

        prompt_input "Git email" ""
        local git_email="$REPLY"

        cat > "$file" << EOF
# ~/.gitconfig.local - Machine-specific git configuration
# This file is included by .gitconfig and is not tracked by git

[user]
    name = $git_name
    email = $git_email

# Optional: signing key
# [user]
#     signingkey = YOUR_GPG_KEY_ID
# [commit]
#     gpgsign = true
EOF
        log_success "Git configuration saved to $file"
    else
        # Non-interactive: create template with placeholders
        cat > "$file" << 'EOF'
# ~/.gitconfig.local - Machine-specific git configuration
# This file is included by .gitconfig and is not tracked by git

# IMPORTANT: Set your user info here
[user]
    name = Your Name
    email = your.email@example.com

# Optional: signing key
# [user]
#     signingkey = YOUR_GPG_KEY_ID
# [commit]
#     gpgsign = true
EOF
        log_info "Please edit $file with your settings"
    fi
}
