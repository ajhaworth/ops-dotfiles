#!/usr/bin/env bash
# platforms/macos/defaults.sh - System preferences orchestrator

# Setup system defaults
setup_defaults() {
    print_header "System Preferences"

    local defaults_dir="$SCRIPT_DIR/platforms/macos/defaults"

    # Close System Settings/Preferences to prevent overriding changes
    # Note: Renamed from "System Preferences" to "System Settings" in macOS Ventura (13+)
    if ! is_dry_run; then
        osascript -e 'tell application "System Settings" to quit' 2>/dev/null || \
        osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
    fi

    # Apply each defaults script
    for script in "$defaults_dir"/*.sh; do
        [[ -f "$script" ]] || continue

        local name
        name="$(basename "$script" .sh)"

        # Skip security settings if not enabled for profile
        if [[ "$name" == "security" ]] && [[ "${PROFILE_APPLY_SECURITY:-true}" != "true" ]]; then
            log_substep "Skipping: $name (disabled for this profile)"
            continue
        fi

        log_step "Applying: $name"

        # Source and run the script
        # shellcheck source=/dev/null
        source "$script"

        # Each script should define an apply_<name> function
        local func="apply_${name}"
        if declare -f "$func" &>/dev/null; then
            if ! "$func"; then
                log_warn "Some preferences in $name may not have been applied"
            fi
        else
            log_warn "No apply function found in $script"
        fi
    done

    log_success "System preferences applied"

    # Restart affected applications
    restart_affected_apps
}

# Restart apps that need to pick up new preferences
restart_affected_apps() {
    log_step "Restarting affected applications"

    local apps=(
        "Dock"
        "Finder"
        "SystemUIServer"
    )

    for app in "${apps[@]}"; do
        if is_dry_run; then
            log_dry "killall $app"
        else
            killall "$app" 2>/dev/null || true
        fi
    done

    log_info "Some changes may require a logout/login to take effect"
}
