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
claude       > claude code settings and hooks
config       > for the noble apps using .config
dictionary   > extend the macos dictionary
git          > global git config and aliases
gnupg        > gpg and gpg-agent config
misc         > extras that are not linked, like obs overlays
mise         > mise for maintaining language versions
nix          > home manager modules that link everything into ~
pi           > pi settings and extensions
ruby         > ruby config
skills       > agent skills
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

**What this does:** Sets up a complete macOS dev environment with shell configs, applications, and tools, linked into place by Home Manager.

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

**Configure secrets (1Password):**

Shell secrets come from 1Password through `op`. Edit `zsh/dot-zsh/00-secrets.tpl` and replace the example names with your real ones, keeping each value a single-quoted `op://Private/dotfiles/NAME` reference.
```bash
bin/secrets-sync --check  # confirms every reference resolves, writes nothing
bin/secrets-sync          # writes zsh/dot-zsh/00-SECRETS.zsh
```
Shell startup never calls `op`; it only sources the generated file. Refreshing is manual: rerun `bin/secrets-sync` whenever a secret or the template changes.

**Customize shell:**
```bash
# Private customizations (not tracked)
vim ~/.zsh/99-custom.zsh
```

## How It Works

### Symlink Management
[Home Manager](https://github.com/nix-community/home-manager) creates symlinks from `~/dotfiles/` to your home directory. `nix/links.nix` lists every link, and `setup-home.sh` builds and activates them with [Nix](https://nixos.org/), which `setup.sh` installs. The links point at this checkout, so editing a file here takes effect without a rebuild. Prezto and the vim dracula theme are flake inputs pinned in `flake.lock`.

### Shell Configuration
ZSH automatically sources all `*.zsh` files from `~/.zsh/` using the [Prezto](https://github.com/sorin-ionescu/prezto) framework for enhanced functionality.

### Package Management
Command-line tools are listed in `nix/packages.nix` and installed by Home Manager into `~/.nix-profile`, at the versions `flake.lock` pins. Homebrew installs everything else through categorized Brewfiles: Requirefile (essentials), Brewfile (formulae Nix cannot take), Caskfile (GUI apps), Fontfile, and Macfile (Mac App Store). CaskfileExtended (optional apps) is installed manually.

### Language Versions
[mise](https://mise.jdx.dev/) manages programming language versions defined in `config/mise/config.toml` for consistent development environments.

## Manual Operations

**Update packages:**
```bash
# Install/update individual brew categories
brew bundle --file brew/Requirefile        # essentials first
brew bundle --file brew/Brewfile           # formulae Nix cannot take
brew bundle --file brew/Caskfile           # GUI apps
brew bundle --file brew/CaskfileQuicklook  # quicklook extensions
brew bundle --file brew/Fontfile           # fonts
brew bundle --file brew/Macfile            # Mac App Store apps
brew bundle --file brew/CaskfileExtended   # optional apps, manual only

# Upgrade the command-line tools in nix/packages.nix
nix flake update nixpkgs && bash setup-home.sh

# Update language versions
mise install --yes && mise reshim
```

**Re-apply symlinks:**
```bash
bash setup-home.sh     # -n previews, -D removes every link, -b backs up a file in the way
```

**Update pinned dependencies:**
```bash
nix flake update prezto dracula-vim   # no names updates nixpkgs and home-manager too
bash setup-home.sh
```

---

**References:**
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [Brewfile: a Gemfile, but for Homebrew](https://thoughtbot.com/blog/brewfile-a-gemfile-but-for-homebrew)
- [Ascii Art Generator with **big** font](https://www.coolgenerator.com/ascii-text-generator)