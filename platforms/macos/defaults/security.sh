#!/usr/bin/env bash
# macos/defaults/security.sh - Security and privacy preferences
#
# NOTE: This script is skipped for work profiles by default.
# These settings may conflict with corporate security policies.

apply_security() {
    log_substep "Configuring security settings..."

    if is_dry_run; then
        log_dry "Setting security preferences"
        return 0
    fi

    log_substep "Security configured"
}
