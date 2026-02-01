#!/usr/bin/env bash
# macos/defaults/keyboard.sh - Keyboard preferences

apply_keyboard() {
    log_substep "Configuring keyboard..."

    if is_dry_run; then
        log_dry "Setting keyboard preferences"
        return 0
    fi

    # Set a fast keyboard repeat rate
    defaults write NSGlobalDomain KeyRepeat -int 2

    # Set a short delay until repeat
    defaults write NSGlobalDomain InitialKeyRepeat -int 15

    # Disable automatic capitalization
    defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

    # Disable smart dashes
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Disable automatic period substitution
    defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

    # Disable smart quotes
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable auto-correct
    defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    # Enable Japanese input (Kotoeri with Romaji typing) if configured
    if [[ "${PROFILE_JAPANESE_INPUT:-false}" == "true" ]]; then
        log_substep "Enabling Japanese input..."
        defaults write com.apple.HIToolbox AppleEnabledInputSources -array \
            '<dict>
                <key>InputSourceKind</key>
                <string>Keyboard Layout</string>
                <key>KeyboardLayout ID</key>
                <integer>0</integer>
                <key>KeyboardLayout Name</key>
                <string>U.S.</string>
            </dict>' \
            '<dict>
                <key>Bundle ID</key>
                <string>com.apple.inputmethod.Kotoeri.RomajiTyping</string>
                <key>InputSourceKind</key>
                <string>Keyboard Input Method</string>
            </dict>' \
            '<dict>
                <key>Bundle ID</key>
                <string>com.apple.inputmethod.Kotoeri.RomajiTyping</string>
                <key>Input Mode</key>
                <string>com.apple.inputmethod.Japanese</string>
                <key>InputSourceKind</key>
                <string>Input Mode</string>
            </dict>'
    fi

    log_substep "Keyboard configured"
}
