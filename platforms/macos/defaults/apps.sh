#!/usr/bin/env bash
# macos/defaults/apps.sh - App-specific preferences

apply_apps() {
    log_substep "Configuring app-specific settings..."

    if is_dry_run; then
        log_dry "Setting app preferences"
        return 0
    fi

    # Safari
    configure_safari

    # TextEdit
    configure_textedit

    # Activity Monitor
    configure_activity_monitor

    # Disk Utility
    configure_disk_utility

    log_substep "App settings configured"
}

configure_safari() {
    # Safari is sandboxed since macOS Mojave (10.14)
    # These preferences cannot be set via defaults write
    # Users should configure Safari manually or via MDM profiles
    :  # no-op
}

configure_textedit() {
    # Use plain text mode for new documents
    defaults write com.apple.TextEdit RichText -int 0

    # Open and save files as UTF-8
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
}

configure_activity_monitor() {
    # Show the main window when launching
    defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

    # Show all processes
    defaults write com.apple.ActivityMonitor ShowCategory -int 0

    # Sort by CPU usage
    defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    defaults write com.apple.ActivityMonitor SortDirection -int 0
}

configure_disk_utility() {
    # Enable the debug menu
    defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
    defaults write com.apple.DiskUtility advanced-image-options -bool true
}

