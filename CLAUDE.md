# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS dotfiles repository that manages system configuration, application settings, and development tools using GNU Stow for symlink management. The repository follows a modular structure where each directory represents a category of configurations.

## Core Commands

### Initial Setup
```bash
# Remote installation (from anywhere)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jasonraimondi/dotfiles/HEAD/install.sh)"

# Local setup (run from cloned repository)
bash setup.sh
```

#### install.sh Details
The `install.sh` script performs a complete macOS development environment setup:

**System Prerequisites:**
- Installs macOS software updates (`sudo softwareupdate --install --all`)
- Installs Xcode Command Line Tools if missing
- Installs Homebrew package manager
- Installs mas-cli and Xcode from Mac App Store
- Configures Xcode license acceptance

**Repository Setup:**
- Clones this dotfiles repository to `~/dotfiles` (or `$DOTFILE_PATH`)
- Initializes git submodules recursively
- **Note**: Script ends after cloning - you must manually run `setup.sh` afterward

### Package Management
```bash
# Update git submodules (especially zprezto)
make pull          # Equivalent to: git submodule update --init --recursive

# Install Homebrew packages
brew bundle --file brew/Requirefile        # Essential packages first
brew bundle --file brew/Brewfile           # Applications
brew bundle --file brew/Fontfile           # Fonts
brew bundle --file brew/Caskfile           # GUI applications
brew bundle --file brew/CaskfileQuicklook  # Quicklook extensions
brew bundle --file brew/Macfile            # Mac App Store apps
```

### Symlink Management (Stow)
```bash
bash setup-stow.sh    # Apply all symlinks using stow --dotfiles

# Individual stow operations (run from repository root):
stow -v -R --dotfiles zsh           # Shell configuration
stow -v -R --dotfiles git           # Git configuration
stow -v -R --dotfiles vim           # Vim configuration
stow -v -R --dotfiles tmux          # Tmux configuration
mkdir -p ~/.config && stow -v -t ~/.config config  # XDG config files
```

### Language Version Management
```bash
mise install --yes   # Install all language versions defined in .tool-versions
mise reshim          # Rebuild shims after installation
```

## Architecture

### Configuration Structure
- **Modular Design**: Each directory (zsh/, git/, vim/, etc.) contains related configuration files
- **Stow Integration**: Uses `--dotfiles` flag to convert `dot-` prefixed files to hidden dotfiles
- **Template System**: Some configs use `.template` files that get copied and customized

### ZSH Configuration System
- **Entry Point**: `~/.zshrc` sources `~/.zsh/_main.zsh`
- **Auto-loading**: `_main.zsh` automatically sources all `*.zsh` files in `~/.zsh/` directory
- **Modular Structure**: Numbered files control load order (00-, 01-, 03-, etc.)
- **Performance Monitoring**: Startup time is measured and displayed
- **Prezto Framework**: Uses git submodule for zsh framework

### Key Directories
- `bin/`: Custom executable scripts (clear-port, movieh264, etc.)
- `brew/`: Homebrew package definitions split by category
- `git/`: Git configuration with template system for user settings
- `zsh/`: Shell configuration with modular loading system
- `config/`: XDG Base Directory compliant configurations
- `mise/`: Language version management configurations

### Security Considerations
- Git user configuration uses template system (`dot-git-user.template`)
- Sensitive files like `dot-git-user` are gitignored
- GPG-encrypted user config available (`dot-git-user.gpg`)
- Private customizations go in `99-custom.zsh` (not tracked)

## Development Workflow

1. **Making Changes**: Edit files in their respective directories
2. **Applying Changes**: Run `bash setup-stow.sh` to update symlinks
3. **Package Updates**: Use appropriate `brew bundle` commands
4. **Submodule Updates**: Run `make pull` for zprezto and other submodules
5. **Testing**: Source shell configurations or restart terminal

## File Templates
When adding new configurations that require user-specific data:
- Create `.template` files for sensitive configurations
- Add the actual config files to `.gitignore`
- Update `setup.sh` to copy templates if missing