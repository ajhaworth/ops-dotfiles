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

    # Check GitHub CLI authentication
    setup_gh_auth

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

# Credential helper (uncomment one based on your OS and preference)
# [credential]
#     helper = osxkeychain                    # macOS Keychain
#     helper = cache --timeout=3600           # Linux: cache for 1 hour
#     helper = store                          # Linux: store in plaintext (~/.git-credentials)
#     helper = /usr/local/share/gcm-core/git-credential-manager  # Git Credential Manager

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

# Credential helper (uncomment one based on your OS and preference)
# [credential]
#     helper = osxkeychain                    # macOS Keychain
#     helper = cache --timeout=3600           # Linux: cache for 1 hour
#     helper = store                          # Linux: store in plaintext (~/.git-credentials)
#     helper = /usr/local/share/gcm-core/git-credential-manager  # Git Credential Manager

# Optional: signing key
# [user]
#     signingkey = YOUR_GPG_KEY_ID
# [commit]
#     gpgsign = true
EOF
        log_info "Please edit $file with your settings"
    fi
}

# Setup GitHub CLI authentication
setup_gh_auth() {
    log_step "Checking GitHub CLI authentication"

    # Check if gh is installed
    if ! command_exists gh; then
        log_substep "GitHub CLI (gh) not installed - skipping"
        return 0
    fi

    # Check if already authenticated
    if gh auth status &>/dev/null; then
        log_substep "GitHub CLI already authenticated"
        return 0
    fi

    log_substep "GitHub CLI not authenticated"

    if is_dry_run; then
        log_dry "Would prompt for GitHub CLI authentication"
        return 0
    fi

    # Only prompt in interactive mode
    if [[ -t 0 ]] && [[ "${FORCE:-false}" != "true" ]]; then
        echo ""
        log_info "GitHub CLI is installed but not authenticated."
        log_info "Authentication enables: git push/pull, PR creation, and more."
        echo ""

        while true; do
            if yes_no "Would you like to authenticate GitHub CLI now?" "y"; then
                echo ""
                log_info "Choose 'Login with a web browser' for easiest setup."
                log_info "If using a token, ensure it has scopes: repo, read:org, workflow"
                echo ""
                gh auth login

                if gh auth status &>/dev/null; then
                    log_success "GitHub CLI authenticated successfully"
                    break
                else
                    echo ""
                    log_warn "GitHub CLI authentication incomplete"
                    if ! yes_no "Would you like to try again?" "y"; then
                        log_info "You can authenticate later with: gh auth login"
                        break
                    fi
                fi
            else
                log_info "Skipped. You can authenticate later with: gh auth login"
                break
            fi
        done
    else
        log_info "Run 'gh auth login' to authenticate"
    fi
}
