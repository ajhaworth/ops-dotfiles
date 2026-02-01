#!/usr/bin/env bash
# platforms/macos/dotfiles.sh - Dotfiles installation

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

    local local_files=(
        "$HOME/.zshrc.local"
        "$HOME/.gitconfig.local"
    )

    for file in "${local_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_substep "Creating: $file"

            if is_dry_run; then
                log_dry "touch $file"
                continue
            fi

            case "$file" in
                *zshrc.local)
                    cat > "$file" << 'EOF'
# ~/.zshrc.local - Machine-specific shell configuration
# This file is sourced by .zshrc and is not tracked by git

# Add your machine-specific aliases and functions here
# Example:
# export PATH="$HOME/custom/bin:$PATH"
# alias myalias='my-command'
EOF
                    ;;
                *gitconfig.local)
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
                    ;;
            esac

            log_info "Please edit $file with your settings"
        else
            log_substep "Already exists: $file"
        fi
    done
}
