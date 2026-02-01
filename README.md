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
- **Modular design**: Skip any component with `--skip-*` flags
- **Idempotent**: Safe to run multiple times
- **Dry-run mode**: Preview changes before applying
- **Dotfiles management**: Symlinked configs with backup support

## Supported Platforms

| Platform | Status |
|----------|--------|
| macOS    | ✅ Fully supported |
| Linux    | 🚧 Planned |
| Windows  | 🚧 Planned |

## Profiles

### Personal (`--profile personal`)

Full installation for personal devices:
- All Homebrew formulae and casks
- Media and graphics apps (Spotify, IINA, Blender, etc.)
- Mac App Store apps
- All system preferences including security settings

### Work (`--profile work`)

Minimal installation for work devices:
- Core development tools only
- Productivity apps (1Password, Raycast, Slack)
- No media, graphics, or gaming apps
- Skips Mac App Store apps
- Preserves corporate security settings

## Command Line Options

```
./setup.sh [options]

Options:
    --profile <name>    Use specified profile (personal, work)
    --dry-run           Show what would be done without making changes
    --skip-homebrew     Skip Homebrew installation and packages
    --skip-dotfiles     Skip dotfiles symlinking
    --skip-defaults     Skip system preferences (macOS)
    --skip-mas          Skip Mac App Store apps
    --force             Skip confirmation prompts
    --help              Show help message
```

## What Gets Installed

### Homebrew Formulae

| Category | Examples |
|----------|----------|
| Core | git, curl, wget, jq, yq |
| Development | node, python, rust, go, terraform |
| Shell | tmux, fzf, starship, zoxide |
| Multimedia | ffmpeg, imagemagick, yt-dlp |
| Network | nmap, iperf3, httpie |

### Homebrew Casks

| Category | Examples |
|----------|----------|
| Productivity | 1Password, Raycast, Obsidian |
| Development | VS Code, Ghostty, Docker, Fork |
| Media | Spotify, IINA, VLC |
| Graphics | Blender, GIMP, Figma |
| Utilities | Keka, iStat Menus, Rectangle |

### Dotfiles

- Shell: `.zshrc`, `.bashrc`, `.aliases`, `.functions`
- Git: `.gitconfig`, `.gitignore_global`
- Tmux: `.tmux.conf`
- Starship: `starship.toml`
- Ghostty: terminal configuration

### macOS Preferences

- Dock: Auto-hide, icon size, animation speed
- Finder: Show hidden files, extensions, path bar
- Keyboard: Key repeat rate, disable auto-correct
- Trackpad: Tap to click, three-finger drag
- Screenshots: Save location, format, disable shadow

## Customization

### Adding Packages

Add packages to the appropriate text file in `packages/macos/`:

```bash
# Add a formula
echo "neovim" >> packages/macos/formulae/development.txt

# Add a cask
echo "figma" >> packages/macos/casks/productivity.txt

# Add a MAS app (ID|Name format)
echo "1475387142|Tailscale" >> packages/macos/mas/apps.txt
```

### Local Overrides

Machine-specific settings go in `.local` files (not tracked by git):

- `~/.zshrc.local` - Shell customizations
- `~/.gitconfig.local` - Git user info and signing key

### Creating a New Profile

1. Copy an existing profile:
   ```bash
   cp profiles/personal.conf profiles/myprofile.conf
   ```

2. Edit the configuration:
   ```bash
   # Enable/disable package categories
   CASKS_MEDIA="false"
   PROFILE_MAS="false"
   ```

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
├── profiles/                   # Profile configs
├── packages/macos/             # Package lists
│   ├── formulae/               # CLI tools
│   ├── casks/                  # GUI apps
│   └── mas/                    # App Store apps
├── dotfiles/                   # Configuration files
├── macos/                      # macOS scripts
│   ├── setup.sh                # Orchestrator
│   ├── homebrew.sh             # Package installer
│   ├── dotfiles.sh             # Symlink installer
│   ├── defaults.sh             # Preferences
│   └── defaults/               # Individual prefs
└── docs/                       # Documentation
```

## Security

This repository is designed to be public and contains no secrets:

- No API keys or tokens
- No passwords or credentials
- No personal email addresses
- No SSH keys

Personal information is stored in local override files:
- `~/.gitconfig.local` - Git user.name and user.email
- `~/.zshrc.local` - Machine-specific exports

## Troubleshooting

### Homebrew installation fails

Ensure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

### MAS apps won't install

Sign into the Mac App Store app first, then run setup again.

### Dotfile symlinks fail

Check for existing files that need to be backed up:
```bash
ls -la ~/.zshrc ~/.gitconfig ~/.tmux.conf
```

### Preferences not applying

Some preferences require a logout/login or restart to take effect.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `./setup.sh --dry-run`
5. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.
