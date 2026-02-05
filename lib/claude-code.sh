#!/usr/bin/env bash
# lib/claude-code.sh - Claude Code installation
#
# Installs Claude Code using the official native installer.
# Works on both macOS and Linux. Auto-updates in the background.

install_claude_code() {
    log_step "Installing Claude Code"

    if [[ "${PROFILE_CLAUDE_CODE:-false}" != "true" ]]; then
        log_info "Skipping Claude Code (disabled in profile)"
        return 0
    fi

    if command_exists claude; then
        log_info "Claude Code already installed: $(claude --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    if is_dry_run; then
        log_dry "curl -fsSL https://claude.ai/install.sh | bash"
        return 0
    fi

    curl -fsSL https://claude.ai/install.sh | bash

    if command_exists claude; then
        log_success "Claude Code installed: $(claude --version 2>/dev/null || echo 'installed')"
    elif [[ -x "$HOME/.local/bin/claude" ]]; then
        log_success "Claude Code installed to ~/.local/bin (will be in PATH after shell restart)"
    else
        log_error "Claude Code installation failed"
    fi
}
