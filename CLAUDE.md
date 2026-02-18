# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

macOS development environment managed with [GNU Stow](https://www.gnu.org/software/stow/) symlinks. Each top-level directory is a stow "package" that maps into `$HOME`.

## Key Commands

```bash
bash setup.sh                    # Full setup (requires sudo)
bash setup-stow.sh               # Re-apply all symlinks
bash setup-stow.sh -n            # Dry-run symlinks
bash setup-stow.sh -D            # Delete all symlinks
brew bundle --file brew/Brewfile  # Install a specific Brewfile category
mise install --yes && mise reshim # Install/update language versions
git submodule update --init --recursive  # Update submodules
```

## Architecture

### Stow Package Layout

Each directory is a stow package. The `--dotfiles` flag (in `.stowrc`) converts `dot-` prefixed files to `.` dotfiles:
- `git/dot-gitconfig` → `~/.gitconfig`
- `zsh/dot-zsh/03-aliases.zsh` → `~/.zsh/03-aliases.zsh`

Most packages target `$HOME`. Exceptions with custom targets:
- `config/` → `~/.config` (XDG apps: karabiner, zed, skillshare, mise)
- `ssh/` → `~/.ssh`
- `dictionary/` → `~/Library/Spelling`

### AI Agent Rules

`ai/AGENT.md` is the canonical agent ruleset, symlinked by `setup-stow.sh` to Claude, Cursor, Windsurf, Junie, and Pi config directories. Edit `ai/AGENT.md` to change rules across all tools.

### Shell (ZSH)

`zsh/dot-zsh/` files are sourced by glob in numeric order:
- `00-SECRETS.zsh` — encrypted credentials (never read/edit)
- `01-*` — base config, exports, PATH
- `02-*` — framework setup
- `03-*` — aliases (general, macOS, programming)
- `04-*` — dev tool config
- `05-*` — utility functions
- `99-custom.zsh` — private, git-ignored

### Homebrew

Separated Brewfiles in `brew/`: `Requirefile` (essentials installed first), `Brewfile`, `Caskfile`, `CaskfileQuicklook`, `Fontfile`, `Macfile`.

### Submodules

zprezto, tmux plugins (dracula, resurrect, sensible, tpm), and vim dracula theme are git submodules.

## Conventions

- **Bash scripts**: Always `#!/usr/bin/env bash` + `set -euo pipefail`, support `--help`/`--dry-run` flags
- **Stow files**: Use `dot-` prefix for dotfiles, never create raw `.` files in packages
- **Commits**: Conventional format — `type(scope): description` (scopes: tool/component names)
- **Private files**: `99-custom.zsh`, `dot-git-user`, `00-SECRETS.zsh` are git-ignored
- **New scripts**: Add to `bin/` — automatically on `$PATH` via `$DOTFILES_HOME/bin`
