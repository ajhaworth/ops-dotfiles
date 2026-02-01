# Setup-OS

Cross-platform workstation setup using simple shell scripts with profile-based customization.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/setup-os.git
cd setup-os

# Run setup with profile selection
./setup.sh

# Or specify a profile directly
./setup.sh --profile personal
./setup.sh --profile work

# Preview changes without making them
./setup.sh --dry-run --profile personal
```

## Features

- **Profile-based configuration**: Different setups for personal vs work devices
- **Modular commands**: Run specific components (homebrew, dotfiles, defaults)
- **Idempotent**: Safe to run multiple times
- **Dry-run mode**: Preview changes before applying
- **Dotfiles management**: Symlinked configs with backup support
- **Status checking**: List commands show what's installed vs missing

## Supported Platforms

| Platform | Status |
|----------|--------|
| macOS    | Supported |
| Linux    | Planned |
| Windows  | Planned |

## Profiles

Profiles control which package categories get installed. Edit `config/profiles/*.conf` to customize.

### Personal (`--profile personal`)

Full installation for personal devices including all package categories, Mac App Store apps, and system preferences.

### Work (`--profile work`)

Minimal installation for work devices - core development tools only, skips media/graphics apps and Mac App Store.

## Usage

```bash
# Full setup (interactive profile selection)
./setup.sh

# Full setup with profile
./setup.sh --profile personal

# Install specific components
./setup.sh homebrew            # All Homebrew packages
./setup.sh formulae            # CLI tools only
./setup.sh casks               # GUI apps only
./setup.sh mas                 # Mac App Store apps only
./setup.sh dotfiles            # Dotfiles only
./setup.sh defaults            # System preferences only

# Check status without making changes
./setup.sh homebrew ls         # Show package status
./setup.sh formulae ls         # Show formulae status
./setup.sh casks ls            # Show cask status
./setup.sh mas ls              # Show MAS app status
./setup.sh dotfiles ls         # Show symlink status
```

### Options

```
--profile <name>    Use specified profile (personal, work)
--dry-run           Show what would be done without making changes
--force             Skip confirmation prompts
--help              Show help message
```

## Customization

### Adding Packages

Packages are defined in text files under `config/packages/macos/`:
- `formulae/*.txt` - Homebrew CLI tools (one package per line)
- `casks/*.txt` - Homebrew GUI apps (one package per line)
- `mas/apps.txt` - Mac App Store apps (`ID|Name` format)

### Local Overrides

Machine-specific settings go in `.local` files (not tracked by git):
- `~/.zshrc.local` - Shell customizations
- `~/.gitconfig.local` - Git user info and signing key

### Creating a New Profile

1. Copy an existing profile:
   ```bash
   cp config/profiles/personal.conf config/profiles/myprofile.conf
   ```

2. Edit the boolean flags to enable/disable package categories

3. Use the new profile:
   ```bash
   ./setup.sh --profile myprofile
   ```

## Project Structure

```
setup-os/
├── setup.sh                    # Entry point
├── lib/                        # Shared libraries
│   ├── common.sh               # Colors, logging
│   ├── detect.sh               # OS detection
│   ├── prompt.sh               # User interaction
│   ├── symlink.sh              # Symlink utilities
│   └── packages.sh             # Package parsing
├── config/
│   ├── profiles/               # Profile configs (personal.conf, work.conf)
│   ├── packages/macos/         # Package lists
│   │   ├── formulae/           # CLI tools
│   │   ├── casks/              # GUI apps
│   │   └── mas/                # App Store apps
│   └── dotfiles/               # Configuration files and manifest
└── platforms/
    └── macos/                  # macOS-specific scripts
        ├── setup.sh            # Orchestrator
        ├── homebrew.sh         # Package installer
        ├── dotfiles.sh         # Symlink installer
        ├── defaults.sh         # Preferences loader
        └── defaults/           # Individual preference scripts
```

## Security

This repository is designed to be public and contains no secrets. Personal information is stored in local override files (`~/.gitconfig.local`, `~/.zshrc.local`).

## Troubleshooting

**Homebrew installation fails** - Ensure Xcode Command Line Tools are installed: `xcode-select --install`

**MAS apps won't install** - Sign into the Mac App Store app first, then run setup again.

**Dotfile symlinks fail** - Existing files will be backed up automatically. Check for conflicts with `./setup.sh dotfiles ls`.

**Preferences not applying** - Some preferences require a logout/login or restart to take effect.

## License

MIT License - See [LICENSE](LICENSE) for details.
