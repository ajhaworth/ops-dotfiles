#!/usr/bin/env bash
#
# setup.sh - Cross-platform workstation setup entry point
#
# Usage:
#   ./setup.sh [command] [subcommand] [options]
#
# Commands:
#   (none)              Run full setup (default)
#   homebrew            Install Homebrew packages (formulae + casks)
#   homebrew ls         List Homebrew packages and status
#   formulae            Install Homebrew formulae only
#   formulae ls         List Homebrew formulae
#   casks               Install Homebrew casks only
#   casks ls            List Homebrew casks
#   mas                 Install Mac App Store apps
#   mas ls              List Mac App Store apps
#   dotfiles            Install/link dotfiles
#   dotfiles ls         List dotfiles and status
#   defaults            Apply system preferences (macOS)
#
# Options:
#   --profile <name>    Use specified profile (personal, work)
#   --dry-run           Show what would be done without making changes
#   --force             Skip confirmation prompts
#   --help              Show this help message
#

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source libraries
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/prompt.sh"
source "$SCRIPT_DIR/lib/symlink.sh"
source "$SCRIPT_DIR/lib/packages.sh"

# Default options
PROFILE=""
DRY_RUN="false"
FORCE="false"

# Export for subshells and sourced scripts
export DRY_RUN FORCE

# Show help
show_help() {
    cat << EOF
Usage: ./setup.sh [command] [subcommand] [options]

Cross-platform workstation setup script.

Commands:
    (none)              Run full setup (default)
    homebrew            Install Homebrew packages (formulae + casks)
    homebrew ls         List Homebrew packages and status
    formulae            Install Homebrew formulae only
    formulae ls         List Homebrew formulae
    casks               Install Homebrew casks only
    casks ls            List Homebrew casks
    mas                 Install Mac App Store apps
    mas ls              List Mac App Store apps
    dotfiles            Install/link dotfiles
    dotfiles ls         List dotfiles and status
    defaults            Apply system preferences (macOS)

Options:
    --profile <name>    Use specified profile (personal, work)
    --dry-run           Show what would be done without making changes
    --force             Skip confirmation prompts
    --help              Show this help message

Examples:
    ./setup.sh                          # Full setup (interactive)
    ./setup.sh --profile personal       # Full setup with profile
    ./setup.sh homebrew                 # Install just Homebrew packages
    ./setup.sh dotfiles                 # Install just dotfiles
    ./setup.sh defaults                 # Apply just system preferences
    ./setup.sh homebrew ls              # List Homebrew packages
    ./setup.sh dotfiles ls              # List dotfiles status

Available profiles:
EOF
    local current_os
    current_os="$(detect_os)"
    for conf in "$SCRIPT_DIR/config/profiles"/*.conf; do
        if [[ -f "$conf" ]]; then
            local name profile_os
            name="$(basename "$conf" .conf)"
            profile_os=$(grep -E "^PROFILE_OS=" "$conf" 2>/dev/null | cut -d'"' -f2)
            # Show if no OS restriction or matches current OS
            if [[ -z "$profile_os" ]] || [[ "$profile_os" == "$current_os" ]]; then
                echo "    - $name"
            fi
        fi
    done
}

# ============================================================================
# Subcommand: dotfiles
# ============================================================================

# Override get_repo_root for subcommands
get_repo_root() {
    echo "$SCRIPT_DIR"
}

cmd_dotfiles_ls() {
    local manifest="$SCRIPT_DIR/config/dotfiles/manifest.txt"

    if [[ ! -f "$manifest" ]]; then
        log_error "Manifest not found: $manifest"
        return 1
    fi

    echo ""
    log_step "Dotfiles"
    echo ""

    # Print header
    printf "  ${BOLD}%-40s  %-50s  %s${RESET}\n" "SOURCE" "DESTINATION" "STATUS"
    printf "  ${DIM}%-40s  %-50s  %s${RESET}\n" "$(printf '─%.0s' {1..40})" "$(printf '─%.0s' {1..50})" "$(printf '─%.0s' {1..12})"

    local count_ok=0
    local count_missing=0
    local count_wrong=0
    local count_conflict=0

    while IFS='|' read -r source destination _ condition || [[ -n "$source" ]]; do
        # Skip empty lines and comments
        [[ -z "$source" ]] && continue
        [[ "$source" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        source="$(echo "$source" | xargs)"
        destination="$(echo "$destination" | xargs)"
        condition="$(echo "${condition:-}" | xargs)"

        # Check condition if specified
        if [[ -n "$condition" ]]; then
            local condition_value="${!condition:-true}"
            if [[ "$condition_value" != "true" ]]; then
                continue
            fi
        fi

        # Make paths absolute
        local abs_source="$source"
        if [[ "$source" != /* ]]; then
            abs_source="$SCRIPT_DIR/$source"
        fi
        local abs_dest="${destination/#\~/$HOME}"

        # Shorten paths for display
        local display_source="${source#config/dotfiles/}"
        local display_dest="${destination/#\~\//~/}"

        # Check symlink status
        local status status_color
        if [[ -L "$abs_dest" ]]; then
            local target
            target="$(readlink "$abs_dest")"
            if [[ "$target" == "$abs_source" ]]; then
                status="linked"
                status_color="${GREEN}"
                ((count_ok++))
            else
                status="wrong target"
                status_color="${YELLOW}"
                ((count_wrong++))
            fi
        elif [[ -e "$abs_dest" ]]; then
            status="conflict"
            status_color="${RED}"
            ((count_conflict++))
        else
            status="missing"
            status_color="${RED}"
            ((count_missing++))
        fi

        printf "  %-40s  %-50s  ${status_color}%s${RESET}\n" "$display_source" "$display_dest" "$status"
    done < "$manifest"

    # Print summary
    echo ""
    printf "  ${DIM}%-40s  %-50s  %s${RESET}\n" "$(printf '─%.0s' {1..40})" "$(printf '─%.0s' {1..50})" "$(printf '─%.0s' {1..12})"
    echo ""
    echo -e "  ${BOLD}Summary:${RESET} ${GREEN}$count_ok linked${RESET}"
    if [[ $count_missing -gt 0 ]]; then
        echo -e "           ${RED}$count_missing missing${RESET}"
    fi
    if [[ $count_wrong -gt 0 ]]; then
        echo -e "           ${YELLOW}$count_wrong wrong target${RESET}"
    fi
    if [[ $count_conflict -gt 0 ]]; then
        echo -e "           ${RED}$count_conflict conflict${RESET} (file exists but not a symlink)"
    fi
    echo ""

    if [[ $count_missing -gt 0 ]] || [[ $count_wrong -gt 0 ]] || [[ $count_conflict -gt 0 ]]; then
        log_info "Run './setup.sh dotfiles' to fix issues"
        echo ""
    fi
}

cmd_dotfiles_install() {
    print_banner
    log_step "Installing dotfiles"

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Process manifest
    local manifest="$SCRIPT_DIR/config/dotfiles/manifest.txt"
    process_manifest "$manifest"

    # Show status
    echo ""
    log_step "Dotfiles status"
    check_manifest "$manifest"

    # Create local override files
    echo ""
    create_local_overrides

    # Check GitHub CLI authentication
    echo ""
    setup_gh_auth

    echo ""
    log_success "Dotfiles installation complete"
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
        # Ensure git is configured to use gh for credentials
        if ! git config --global --get credential.https://github.com.helper | grep -q "gh auth"; then
            log_substep "Configuring git to use GitHub CLI for credentials"
            gh auth setup-git
        fi
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
                    # Configure git to use gh for credentials
                    log_substep "Configuring git to use GitHub CLI for credentials"
                    gh auth setup-git
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

# ============================================================================
# Subcommand: packages (Linux)
# ============================================================================

cmd_packages_ls() {
    print_banner
    log_step "Linux packages status"
    echo ""
    check_packages
    echo ""
}

cmd_packages_install() {
    print_banner
    log_step "Installing Linux packages"

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    setup_packages

    echo ""
    log_success "Package installation complete"
}

# ============================================================================
# Subcommand: homebrew/formulae/casks/mas
# ============================================================================

# Package directories
FORMULAE_DIR="$SCRIPT_DIR/config/packages/macos/formulae"
CASKS_DIR="$SCRIPT_DIR/config/packages/macos/casks"
MAS_DIR="$SCRIPT_DIR/config/packages/macos/mas"

# Cache for installed packages
INSTALLED_FORMULAE=""
INSTALLED_CASKS=""
INSTALLED_MAS=""

# Get list of installed formulae (cached)
get_installed_formulae() {
    if [[ -z "$INSTALLED_FORMULAE" ]]; then
        if command -v brew &>/dev/null; then
            INSTALLED_FORMULAE=$(brew list --formula 2>/dev/null || echo "")
        fi
    fi
    echo "$INSTALLED_FORMULAE"
}

# Get list of installed casks (cached)
get_installed_casks() {
    if [[ -z "$INSTALLED_CASKS" ]]; then
        if command -v brew &>/dev/null; then
            INSTALLED_CASKS=$(brew list --cask 2>/dev/null || echo "")
        fi
    fi
    echo "$INSTALLED_CASKS"
}

# Get list of installed MAS apps (cached)
get_installed_mas() {
    if [[ -z "$INSTALLED_MAS" ]]; then
        if command -v mas &>/dev/null; then
            INSTALLED_MAS=$(mas list 2>/dev/null | awk '{print $1}' || echo "")
        fi
    fi
    echo "$INSTALLED_MAS"
}

# Check if a formula is installed (handles versioned packages like python@3.14)
is_formula_installed() {
    local formula="$1"
    [[ -n "$(get_installed_formulae | grep -E "^${formula}(@|$)")" ]]
}

# Check if a cask is installed
is_cask_installed() {
    local cask="$1"
    [[ -n "$(get_installed_casks | grep -E "^${cask}$")" ]]
}

# Check if a MAS app is installed
is_mas_installed() {
    local app_id="$1"
    [[ -n "$(get_installed_mas | grep -E "^${app_id}$")" ]]
}

cmd_formulae_ls() {
    echo ""
    log_step "Homebrew Formulae"
    echo ""

    if [[ ! -d "$FORMULAE_DIR" ]]; then
        log_warn "Formulae directory not found: $FORMULAE_DIR"
        return 1
    fi

    local total_count=0
    local installed_count=0
    local missing_count=0

    for file in "$FORMULAE_DIR"/*.txt; do
        [[ -f "$file" ]] || continue

        local category
        category="$(basename "$file" .txt)"

        echo -e "  ${BOLD}${category}${RESET}"

        while IFS= read -r package || [[ -n "$package" ]]; do
            package="$(echo "$package" | xargs)"
            [[ -z "$package" ]] && continue
            [[ "$package" =~ ^# ]] && continue
            package="${package%%#*}"
            package="$(echo "$package" | xargs)"
            [[ -z "$package" ]] && continue

            ((total_count++))

            local status status_color
            if is_formula_installed "$package"; then
                status="installed"
                status_color="${GREEN}"
                ((installed_count++))
            else
                status="missing"
                status_color="${RED}"
                ((missing_count++))
            fi

            printf "    %-35s ${status_color}%s${RESET}\n" "$package" "$status"
        done < "$file"

        echo ""
    done

    printf "  ${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..50})"
    echo -e "  ${BOLD}Summary:${RESET} ${GREEN}$installed_count installed${RESET}, ${RED}$missing_count missing${RESET} (of $total_count total)"
    echo ""
}

cmd_casks_ls() {
    echo ""
    log_step "Homebrew Casks"
    echo ""

    if [[ ! -d "$CASKS_DIR" ]]; then
        log_warn "Casks directory not found: $CASKS_DIR"
        return 1
    fi

    local total_count=0
    local installed_count=0
    local missing_count=0

    for file in "$CASKS_DIR"/*.txt; do
        [[ -f "$file" ]] || continue

        local category
        category="$(basename "$file" .txt)"

        echo -e "  ${BOLD}${category}${RESET}"

        while IFS= read -r package || [[ -n "$package" ]]; do
            package="$(echo "$package" | xargs)"
            [[ -z "$package" ]] && continue
            [[ "$package" =~ ^# ]] && continue
            package="${package%%#*}"
            package="$(echo "$package" | xargs)"
            [[ -z "$package" ]] && continue

            ((total_count++))

            local status status_color
            if is_cask_installed "$package"; then
                status="installed"
                status_color="${GREEN}"
                ((installed_count++))
            else
                status="missing"
                status_color="${RED}"
                ((missing_count++))
            fi

            printf "    %-35s ${status_color}%s${RESET}\n" "$package" "$status"
        done < "$file"

        echo ""
    done

    printf "  ${DIM}%s${RESET}\n" "$(printf '─%.0s' {1..50})"
    echo -e "  ${BOLD}Summary:${RESET} ${GREEN}$installed_count installed${RESET}, ${RED}$missing_count missing${RESET} (of $total_count total)"
    echo ""
}

cmd_mas_ls() {
    echo ""
    log_step "Mac App Store Apps"
    echo ""

    local mas_file="$MAS_DIR/apps.txt"

    if [[ ! -f "$mas_file" ]]; then
        log_warn "MAS apps file not found: $mas_file"
        return 1
    fi

    printf "  ${BOLD}%-12s  %-35s  %s${RESET}\n" "APP ID" "NAME" "STATUS"
    printf "  ${DIM}%-12s  %-35s  %s${RESET}\n" "$(printf '─%.0s' {1..12})" "$(printf '─%.0s' {1..35})" "$(printf '─%.0s' {1..12})"

    local total_count=0
    local installed_count=0
    local missing_count=0

    while IFS='|' read -r id name || [[ -n "$id" ]]; do
        id="$(echo "$id" | xargs)"
        name="$(echo "$name" | xargs)"

        [[ -z "$id" ]] && continue
        [[ "$id" =~ ^# ]] && continue
        [[ "$id" =~ ^[0-9]+$ ]] || continue

        ((total_count++))

        local status status_color
        if is_mas_installed "$id"; then
            status="installed"
            status_color="${GREEN}"
            ((installed_count++))
        else
            status="missing"
            status_color="${RED}"
            ((missing_count++))
        fi

        printf "  %-12s  %-35s  ${status_color}%s${RESET}\n" "$id" "$name" "$status"
    done < "$mas_file"

    echo ""
    printf "  ${DIM}%-12s  %-35s  %s${RESET}\n" "$(printf '─%.0s' {1..12})" "$(printf '─%.0s' {1..35})" "$(printf '─%.0s' {1..12})"
    echo -e "  ${BOLD}Summary:${RESET} ${GREEN}$installed_count installed${RESET}, ${RED}$missing_count missing${RESET} (of $total_count total)"
    echo ""
}

cmd_homebrew_ls() {
    cmd_formulae_ls
    cmd_casks_ls
}

# ============================================================================
# Install commands (run actual installation)
# ============================================================================

cmd_homebrew_install() {
    print_banner

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Load profile if specified
    if [[ -n "$PROFILE" ]]; then
        load_profile "$PROFILE"
    fi

    source "$SCRIPT_DIR/platforms/macos/homebrew.sh"
    setup_homebrew

    echo ""
    log_success "Homebrew setup complete"
}

cmd_formulae_install() {
    print_banner

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Load profile if specified
    if [[ -n "$PROFILE" ]]; then
        load_profile "$PROFILE"
    fi

    source "$SCRIPT_DIR/platforms/macos/homebrew.sh"
    install_homebrew
    update_homebrew
    install_formulae
    cleanup_homebrew

    echo ""
    log_success "Formulae installation complete"
}

cmd_casks_install() {
    print_banner

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Load profile if specified
    if [[ -n "$PROFILE" ]]; then
        load_profile "$PROFILE"
    fi

    source "$SCRIPT_DIR/platforms/macos/homebrew.sh"
    install_homebrew
    update_homebrew
    install_casks
    cleanup_homebrew

    echo ""
    log_success "Casks installation complete"
}

cmd_mas_install() {
    print_banner

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    source "$SCRIPT_DIR/platforms/macos/homebrew.sh"
    install_homebrew
    install_mas_apps

    echo ""
    log_success "Mac App Store apps installation complete"
}

cmd_defaults_apply() {
    print_banner

    if is_dry_run; then
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Load profile if specified
    if [[ -n "$PROFILE" ]]; then
        load_profile "$PROFILE"
    fi

    source "$SCRIPT_DIR/platforms/macos/defaults.sh"
    setup_defaults

    echo ""
    log_success "System preferences applied"
}

# ============================================================================
# Argument parsing
# ============================================================================

# Parse options from arguments (returns remaining args)
parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --profile=*)
                PROFILE="${1#*=}"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --force|-f)
                FORCE="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                # Not an option, stop parsing
                break
                ;;
        esac
    done
    # Return remaining arguments
    echo "$@"
}

# Load profile configuration
load_profile() {
    local profile_name="$1"
    local profile_file="$SCRIPT_DIR/config/profiles/${profile_name}.conf"

    if [[ ! -f "$profile_file" ]]; then
        log_error "Profile not found: $profile_name"
        log_info "Available profiles:"
        for conf in "$SCRIPT_DIR/config/profiles"/*.conf; do
            if [[ -f "$conf" ]]; then
                echo "  - $(basename "$conf" .conf)"
            fi
        done
        exit 1
    fi

    log_info "Loading profile: $profile_name"

    # Source the profile
    # shellcheck source=/dev/null
    source "$profile_file"

    # Export profile variables
    export PROFILE_NAME="$profile_name"
}

# Handle subcommands
handle_subcommand() {
    local cmd="${1:-}"
    local subcmd="${2:-}"

    case "$cmd" in
        dotfiles)
            case "$subcmd" in
                ls|list)
                    cmd_dotfiles_ls
                    ;;
                ""|install)
                    cmd_dotfiles_install
                    ;;
                *)
                    log_error "Unknown subcommand: dotfiles $subcmd"
                    log_info "Available: ls, install (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
        packages)
            # Linux package management
            if [[ "$(detect_os)" != "linux" ]]; then
                log_error "packages command is only available on Linux"
                log_info "On macOS, use: homebrew, formulae, casks, or mas"
                exit 1
            fi
            source "$SCRIPT_DIR/platforms/linux/packages.sh"
            case "$subcmd" in
                ls|list)
                    cmd_packages_ls
                    ;;
                ""|install)
                    cmd_packages_install
                    ;;
                *)
                    log_error "Unknown subcommand: packages $subcmd"
                    log_info "Available: ls, install (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
        homebrew|brew)
            case "$subcmd" in
                ls|list)
                    cmd_homebrew_ls
                    ;;
                ""|install)
                    cmd_homebrew_install
                    ;;
                *)
                    log_error "Unknown subcommand: homebrew $subcmd"
                    log_info "Available: ls, install (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
        formulae|formula)
            case "$subcmd" in
                ls|list)
                    cmd_formulae_ls
                    ;;
                ""|install)
                    cmd_formulae_install
                    ;;
                *)
                    log_error "Unknown subcommand: formulae $subcmd"
                    log_info "Available: ls, install (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
        casks|cask)
            case "$subcmd" in
                ls|list)
                    cmd_casks_ls
                    ;;
                ""|install)
                    cmd_casks_install
                    ;;
                *)
                    log_error "Unknown subcommand: casks $subcmd"
                    log_info "Available: ls, install (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
        mas)
            case "$subcmd" in
                ls|list)
                    cmd_mas_ls
                    ;;
                ""|install)
                    cmd_mas_install
                    ;;
                *)
                    log_error "Unknown subcommand: mas $subcmd"
                    log_info "Available: ls, install (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
        defaults)
            case "$subcmd" in
                ""|apply)
                    cmd_defaults_apply
                    ;;
                *)
                    log_error "Unknown subcommand: defaults $subcmd"
                    log_info "Available: apply (default)"
                    exit 1
                    ;;
            esac
            exit 0
            ;;
    esac

    # Not a recognized subcommand
    return 1
}

# Full setup logic
run_full_setup() {
    # Show banner
    print_banner

    # Detect OS
    local os
    os="$(detect_os)"
    print_system_info

    # Validate OS
    if [[ "$os" == "unknown" ]]; then
        log_error "Unsupported operating system"
        exit 1
    fi

    # Prompt for profile if not specified
    if [[ -z "$PROFILE" ]]; then
        select_profile "$os"
        PROFILE="$REPLY"
    fi

    # Load profile
    load_profile "$PROFILE"

    # Show dry-run notice
    if is_dry_run; then
        echo ""
        log_warn "DRY-RUN MODE - No changes will be made"
        echo ""
    fi

    # Show what will be done
    echo ""
    log_step "Setup configuration"
    echo "  Profile:      $PROFILE"

    # Check if any Homebrew packages are enabled
    local homebrew_enabled="false"
    for var in FORMULAE_CORE FORMULAE_SHELL FORMULAE_SOFTWARE_DEV FORMULAE_DEVOPS FORMULAE_MEDIA \
               CASKS_PRODUCTIVITY CASKS_DEVELOPMENT CASKS_UTILITIES CASKS_POWER_USER CASKS_BROWSERS CASKS_CREATIVE CASKS_MEDIA; do
        if [[ "${!var:-false}" == "true" ]]; then
            homebrew_enabled="true"
            break
        fi
    done

    if [[ "$os" == "macos" ]]; then
        echo "  Homebrew:     $(if [[ "$homebrew_enabled" == "true" ]]; then echo "install"; else echo "skip (profile)"; fi)"
        echo "  Dotfiles:     $(if [[ "${PROFILE_DOTFILES:-true}" == "false" ]]; then echo "skip (profile)"; else echo "install"; fi)"
        echo "  Defaults:     $(if [[ "${PROFILE_APPLY_DEFAULTS:-true}" == "false" ]]; then echo "skip (profile)"; else echo "apply"; fi)"
        echo "  MAS Apps:     $(if [[ "${PROFILE_MAS:-true}" == "false" ]]; then echo "skip (profile)"; else echo "install"; fi)"
    elif [[ "$os" == "linux" ]]; then
        echo "  Dotfiles:     $(if [[ "${PROFILE_DOTFILES:-true}" == "false" ]]; then echo "skip (profile)"; else echo "install"; fi)"
    fi
    echo ""

    # Confirm before proceeding
    if ! is_dry_run && [[ "$FORCE" != "true" ]]; then
        if ! yes_no "Proceed with setup?"; then
            log_info "Setup cancelled"
            exit 0
        fi
    fi

    # Dispatch to OS-specific setup
    case "$os" in
        macos)
            if [[ -f "$SCRIPT_DIR/platforms/macos/setup.sh" ]]; then
                # Set variables for full setup (no skipping)
                export SKIP_HOMEBREW="false"
                export SKIP_DOTFILES="false"
                export SKIP_DEFAULTS="false"
                export SKIP_MAS="false"

                source "$SCRIPT_DIR/platforms/macos/setup.sh"
                macos_setup
            else
                log_error "macOS setup script not found"
                exit 1
            fi
            ;;
        linux)
            if [[ -f "$SCRIPT_DIR/platforms/linux/setup.sh" ]]; then
                source "$SCRIPT_DIR/platforms/linux/setup.sh"
                linux_setup
            else
                log_warn "Linux setup not yet implemented"
                exit 1
            fi
            ;;
        windows)
            log_warn "Windows setup not yet implemented"
            log_info "Please run setup.ps1 in PowerShell instead"
            exit 1
            ;;
    esac

    # Done
    echo ""
    print_header "Setup Complete"
    log_success "Workstation setup finished successfully!"

    if is_dry_run; then
        echo ""
        log_info "This was a dry run. Run without --dry-run to apply changes."
    else
        echo ""
        log_info "You may need to restart your terminal or log out/in for all changes to take effect."
    fi
}

# Check that script is not run as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script as root/sudo"
        log_error "Homebrew requires non-root execution"
        log_info "Run: ./setup.sh (without sudo)"
        exit 1
    fi
}

# Main entry point
main() {
    # Prevent running as root (Homebrew requirement)
    check_not_root

    local args=()
    local cmd=""
    local subcmd=""

    # First pass: extract options and collect non-option args
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --profile=*)
                PROFILE="${1#*=}"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            --force|-f)
                FORCE="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    # Export options
    export DRY_RUN FORCE

    # Load profile if specified (needed for subcommands)
    if [[ -n "${PROFILE:-}" ]]; then
        load_profile "$PROFILE"
    fi

    # Check for subcommands
    if [[ ${#args[@]} -gt 0 ]]; then
        cmd="${args[0]}"
        subcmd="${args[1]:-}"

        # Try to handle as subcommand
        if handle_subcommand "$cmd" "$subcmd"; then
            exit 0
        fi

        # If we get here, it wasn't a valid subcommand
        log_error "Unknown command: $cmd"
        show_help
        exit 1
    fi

    # No subcommand - run full setup
    run_full_setup
}

# Run main
main "$@"
