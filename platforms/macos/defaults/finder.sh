#!/usr/bin/env bash
# macos/defaults/finder.sh - Finder preferences

apply_finder() {
    log_substep "Configuring Finder..."

    if is_dry_run; then
        log_dry "Setting Finder preferences"
        return 0
    fi

    # Show hidden files
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # Keep folders on top when sorting by name
    defaults write com.apple.finder _FXSortFoldersFirst -bool true

    # When performing a search, search the current folder by default
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Disable the warning when changing a file extension
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

    # Avoid creating .DS_Store files on network or USB volumes
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    # Use list view in all Finder windows by default
    # Four-letter codes for view modes: icnv, clmv, glyv, Nlsv
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Show the ~/Library folder
    chflags nohidden ~/Library

    # Show the /Volumes folder
    sudo chflags nohidden /Volumes 2>/dev/null || true

    # Expand save panel by default
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

    # Expand print panel by default
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

    # Set Desktop as the default location for new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfDe"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

    # Disable window and Get Info animations
    defaults write com.apple.finder DisableAllAnimations -bool true

    log_substep "Finder configured"
}
