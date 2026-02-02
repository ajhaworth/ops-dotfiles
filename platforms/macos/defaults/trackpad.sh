#!/usr/bin/env bash
# macos/defaults/trackpad.sh - Trackpad preferences

apply_trackpad() {
    log_substep "Configuring trackpad..."

    if is_dry_run; then
        log_dry "Setting trackpad preferences"
        return 0
    fi

    # Enable tap to click for this user and for the login screen
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    # Enable natural scrolling
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

    # Enable secondary click (right click)
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

    log_substep "Trackpad configured"
}
