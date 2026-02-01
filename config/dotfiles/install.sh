#!/usr/bin/env bash
# config/dotfiles/install.sh - Standalone dotfiles installer
#
# This is a convenience wrapper around the main setup.sh script.
# Usage: ./config/dotfiles/install.sh [ls|install] [--dry-run]

set -euo pipefail

# Get repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Delegate to main setup.sh
exec "$REPO_ROOT/setup.sh" dotfiles "$@"
