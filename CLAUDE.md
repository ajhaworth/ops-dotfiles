# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Setup-OS is a cross-platform workstation setup tool using shell scripts. It automates the installation of packages, dotfiles, and system preferences across macOS (primary), with Linux and Windows support planned.

## Key Concepts

### Profiles

Profiles (`config/profiles/*.conf`) control what gets installed:
- `personal.conf` - Full installation for personal devices
- `work.conf` - Minimal installation for work devices

Profile variables control which package categories are enabled:
- `FORMULAE_*` - Homebrew formula categories
- `CASKS_*` - Homebrew cask categories
- `PROFILE_MAS` - Mac App Store apps
- `PROFILE_APPLY_SECURITY` - Security preferences

### Package Lists

Packages are defined in text files under `config/packages/macos/`:
- One package per line
- Comments start with `#`
- MAS apps use `ID|Name` format

### Dotfiles

Dotfiles use symlinks managed via `config/dotfiles/manifest.txt`:
- Format: `source|destination`
- Existing files are backed up before linking
- Local overrides (`.local` files) are not tracked

### macOS Defaults

System preferences are set via `defaults write` commands in `platforms/macos/defaults/*.sh`. Each file defines an `apply_<name>()` function.

## Commands

```bash
# Full setup (interactive profile selection)
./setup.sh

# Full setup with profile
./setup.sh --profile personal
./setup.sh --profile work

# Dry run to preview changes
./setup.sh --dry-run --profile personal

# Install specific components
./setup.sh homebrew            # Homebrew packages only
./setup.sh dotfiles            # Dotfiles only
./setup.sh defaults            # System preferences only
./setup.sh formulae            # CLI tools only
./setup.sh casks               # GUI apps only
./setup.sh mas                 # Mac App Store apps only

# List/check status (no changes)
./setup.sh homebrew ls         # Show package status
./setup.sh dotfiles ls         # Show symlink status
./setup.sh formulae ls         # Show formulae status
./setup.sh casks ls            # Show cask status
./setup.sh mas ls              # Show MAS app status
```

## Common Tasks

### Adding a new Homebrew package

Add to appropriate category file in `config/packages/macos/`:
- `formulae/core.txt` - Essential CLI tools
- `formulae/shell.txt` - Shell enhancements
- `formulae/software-dev.txt` - Programming languages/tools
- `formulae/devops.txt` - Infrastructure tools
- `formulae/media.txt` - Media processing CLI tools
- `casks/productivity.txt` - Productivity apps
- `casks/development.txt` - Development apps
- `casks/utilities.txt` - System utilities
- `casks/creative.txt` - Graphics/design apps
- `casks/media.txt` - Media player apps

### Adding a new dotfile

1. Create the config file in `config/dotfiles/`
2. Add mapping to `config/dotfiles/manifest.txt` using `source|destination` format
3. Test with `./setup.sh dotfiles --dry-run`

### Adding a new macOS preference

1. Create or edit file in `platforms/macos/defaults/`
2. Define `apply_<filename>()` function
3. Check `is_dry_run` before running `defaults write` commands

### Adding a new profile

1. Copy existing profile: `cp config/profiles/personal.conf config/profiles/newprofile.conf`
2. Edit boolean flags to enable/disable package categories
3. Run with `./setup.sh --profile newprofile`

## Code Style

- Shell scripts use bash with `set -euo pipefail`
- Functions are documented with comments
- Use library functions from `lib/` for consistency:
  - `log_info`, `log_success`, `log_warn`, `log_error` for output
  - `is_dry_run` to check dry-run mode
  - `run_cmd` to execute commands respecting dry-run

## Architecture

```
setup.sh (entry point)
    ├── Parses arguments and handles subcommands (homebrew, dotfiles, defaults, etc.)
    ├── Detects OS via lib/detect.sh
    ├── Loads profile from config/profiles/*.conf
    └── Dispatches to platforms/macos/setup.sh
            ├── platforms/macos/homebrew.sh (install_formulae, install_casks, install_mas_apps)
            ├── platforms/macos/dotfiles.sh (process_manifest, check_manifest)
            └── platforms/macos/defaults.sh (sources all defaults/*.sh files)
```

### Profile Variable Naming

Profile variables follow a naming convention that maps to package directories:
- `FORMULAE_CORE` → `config/packages/macos/formulae/core.txt`
- `CASKS_PRODUCTIVITY` → `config/packages/macos/casks/productivity.txt`
- Variable names use underscores, directory names use hyphens (e.g., `FORMULAE_SOFTWARE_DEV` → `software-dev.txt`)

## Security Considerations

This repo is public-safe:
- Personal data goes in `.local` files (gitignored)
- Git user.email is set in `~/.gitconfig.local`
