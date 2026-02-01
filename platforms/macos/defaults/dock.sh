#!/usr/bin/env bash
# macos/defaults/dock.sh - Dock preferences

apply_dock() {
    log_substep "Configuring Dock..."

    if is_dry_run; then
        log_dry "Setting Dock preferences"
        return 0
    fi

    # Auto-hide the Dock
    defaults write com.apple.dock autohide -bool true

    # Set the icon size of Dock items (max: 128)
    defaults write com.apple.dock tilesize -int 128

    # Magnification
    defaults write com.apple.dock magnification -bool false

    # Minimize windows into their application's icon
    defaults write com.apple.dock minimize-to-application -bool true

    # Show indicator lights for open applications
    defaults write com.apple.dock show-process-indicators -bool true

    # Don't animate opening applications
    defaults write com.apple.dock launchanim -bool false

    # Don't show recent applications in Dock
    defaults write com.apple.dock show-recents -bool false

    # Minimize windows using scale effect (faster than genie)
    defaults write com.apple.dock mineffect -string "scale"

    # Position on screen (left, bottom, right)
    defaults write com.apple.dock orientation -string "bottom"

    # Make Dock icons of hidden applications translucent
    defaults write com.apple.dock showhidden -bool true

    # Don't rearrange Spaces based on most recent use
    defaults write com.apple.dock mru-spaces -bool false

    log_substep "Dock configured"
}
