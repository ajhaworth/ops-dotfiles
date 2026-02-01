#!/usr/bin/env bash
# macos/defaults/screenshots.sh - Screenshot preferences

apply_screenshots() {
    log_substep "Configuring screenshots..."

    if is_dry_run; then
        log_dry "Setting screenshot preferences"
        return 0
    fi

    # Create screenshots directory
    local screenshot_dir="$HOME/Pictures/Screenshots"
    mkdir -p "$screenshot_dir"

    # Save screenshots to ~/Pictures/Screenshots
    defaults write com.apple.screencapture location -string "$screenshot_dir"

    # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF, HEIC)
    # NOTE: macOS 26 Tahoe defaults to HEIC format. This explicitly sets PNG.
    defaults write com.apple.screencapture type -string "png"

    # Disable shadow in screenshots
    defaults write com.apple.screencapture disable-shadow -bool true

    # Include date in screenshot filename
    defaults write com.apple.screencapture include-date -bool true

    log_substep "Screenshots configured"
}
