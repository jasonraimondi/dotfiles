```md
 _____   ____ _______ ______ _____ _      ______  _____ 
|  __ \ / __ \__   __|  ____|_   _| |    |  ____|/ ____|
| |  | | |  | | | |  | |__    | | | |    | |__  | (___  
| |  | | |  | | | |  |  __|   | | | |    |  __|  \___ \ 
| |__| | |__| | | |  | |     _| |_| |____| |____ ____) |
|_____/ \____/  |_|  |_|    |_____|______|______|_____/ 

> macOS development environment setup with modular dotfiles

aws          > amazon is taking over the world
bin          > custom bin scripts
brew         > homebrew all the things
config       > for the noble apps using .config
dictionary   > extend the macos dictionary
git          > global git config and aliases
mackup       > mackup config
mcp          > manage mcp.json config(s)
mise         > mise for maintaining language versions
obs          > various tools for obs
ssh          > ssh config
tmux         > tmux config
vim          > vim configs
zprezto      > framework for Zsh 
zsh          > shell configuration 🔥🔥
```

## Quick Start

**One-liner remote install:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jasonraimondi/dotfiles/HEAD/install.sh)"
```

**Then run setup:**
```bash
cd dotfiles && bash setup.sh
```

**What this does:** Sets up a complete macOS dev environment with shell configs, applications, and tools managed through GNU Stow symlinks.

## Post-Install Setup

**Configure git user (required):**
```bash
# Edit the template file with your info
vim git/dot-git-user
```

**Generate SSH key:**
```bash
ssh-keygen -t ed25519
cat ~/.ssh/id_ed25519.pub | pbcopy  # copies to clipboard
```
Add to [GitHub](https://github.com/settings/keys)

**Customize shell:**
```bash
# Private customizations (not tracked)
vim ~/.zsh/99-custom.zsh
```

## How It Works

### Symlink Management
[GNU Stow](https://www.gnu.org/software/stow/) creates symlinks from `~/dotfiles/` to your home directory. The `--dotfiles` flag converts `dot-example` files to `.example` dotfiles.

### Shell Configuration
ZSH automatically sources all `*.zsh` files from `~/.zsh/` using the [Prezto](https://github.com/sorin-ionescu/prezto) framework for enhanced functionality.

### Package Management
Homebrew installs software through categorized Brewfiles: Requirefile (essentials), Brewfile (CLI tools), Caskfile (GUI apps), Fontfile, and Macfile (Mac App Store).

### Language Versions
[mise](https://mise.jdx.dev/) manages programming language versions defined in `.tool-versions` for consistent development environments.

## Manual Operations

**Update packages:**
```bash
# Install/update individual brew categories
brew bundle --file brew/Requirefile        # essentials first
brew bundle --file brew/Brewfile           # CLI tools  
brew bundle --file brew/Caskfile           # GUI apps
brew bundle --file brew/CaskfileQuicklook  # quicklook extensions
brew bundle --file brew/Fontfile           # fonts
brew bundle --file brew/Macfile            # Mac App Store apps

# Update language versions
mise install --yes && mise reshim
```

**Re-apply symlinks:**
```bash
bash setup-stow.sh
```

**Update submodules:**
```bash
git submodule update --init --recursive
```

---

**References:**
- [Managing dotfiles with GNU Stow](https://alexpearce.me/2016/02/managing-dotfiles-with-stow/)
- [Brewfile: a Gemfile, but for Homebrew](https://thoughtbot.com/blog/brewfile-a-gemfile-but-for-homebrew)
- [Ascii Art Generator with **big** font](https://www.coolgenerator.com/ascii-text-generator)