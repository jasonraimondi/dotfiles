# AGENTS.md

This file provides guidance to coding agents working with code in this repository.

## Overview

macOS development environment managed with [GNU Stow](https://www.gnu.org/software/stow/) symlinks. Each directory that `setup-stow.sh` stows is a "package" that maps into `$HOME`. `misc/` is not stowed and holds files kept for reference, like the OBS overlays. `skills/` holds agent skills plus the Claude and Pi settings, linked by its own `skills/setup.sh`; `skills/AGENTS.md` is the global agent instructions file that script links to `~/.claude/CLAUDE.md`.

## Key Commands

```bash
bash setup.sh                    # Full setup (requires sudo)
bash setup-stow.sh               # Re-apply all symlinks
bash setup-stow.sh -n            # Dry-run symlinks
bash setup-stow.sh -D            # Delete all symlinks
bash skills/setup.sh             # Link agent skills and settings (-n dry-run, -D delete)
brew bundle --file brew/Brewfile  # Install a specific Brewfile category
mise install --yes && mise reshim # Install/update language versions
git submodule update --init --recursive  # Update submodules
bin/secrets-sync                 # Render 00-SECRETS.zsh from 1Password (--check validates only)
```

## Architecture

### Stow Package Layout

Each directory is a stow package. The `--dotfiles` flag (in `.stowrc`) converts `dot-` prefixed files to `.` dotfiles:
- `git/dot-gitconfig` → `~/.gitconfig`
- `zsh/dot-zsh/03-aliases.zsh` → `~/.zsh/03-aliases.zsh`

Most packages target `$HOME`. Exceptions with custom targets:
- `config/` → `~/.config` (XDG apps: atuin, herdr, karabiner, mise, zed)
- `ssh/` → `~/.ssh`
- `gnupg/` → `~/.gnupg`
- `dictionary/` → `~/Library/Spelling`

### Shell (ZSH)

`zsh/dot-zsh/` files are sourced by glob in numeric order:
- `00-SECRETS.zsh` — credentials rendered from the committed `00-secrets.tpl` (1Password `op://` references) by a manual `bin/secrets-sync` run; `bin/secrets-sync --check` validates the references without writing (never read or edit `00-SECRETS.zsh`)
- `01-*` — base config, exports
- `02-*` — framework setup, plus atuin/direnv/mise init cached under `~/.cache/zsh`
- `03-*` — aliases (general, macOS, programming)
- `04-*` — prompt tweaks
- `05-*` — utility functions
- `01.5-custom.zsh`, `99-custom.zsh` — private, git-ignored

PATH, `DOTFILES_HOME` and `brew shellenv` live in `zprezto/dot-zprofile`, which login shells source; non-login shells source it through `zprezto/dot-zshenv` when `DOTFILES_HOME` is unset.

### Homebrew

Separated Brewfiles in `brew/`: `Requirefile` (essentials installed first), `Brewfile`, `Caskfile`, `CaskfileQuicklook`, `Fontfile`, `Macfile`. `CaskfileExtended` holds optional apps and is installed manually.

### Submodules

zprezto and the vim dracula theme are git submodules.

## Conventions

- **Public repo**: Every commit is published on GitHub. Before committing, read the staged diff for anything not meant for release: secrets and credentials, private hostnames or IPs, email addresses, and any text about work (employer, coworkers, clients, internal tools or repos), other people, or private life. If any appear, refuse to commit and report what you found. Sensitive values belong in the git-ignored private files or 1Password; terms that must never appear go in the git-ignored `.gitleaks.private.toml`, which the pre-commit hook enforces.
- **Bash scripts**: Always `#!/usr/bin/env bash` + `set -euo pipefail`
- **Stow files**: Use `dot-` prefix for dotfiles, never create raw `.` files in packages
- **Commits**: Conventional format — `type(scope): description` (scopes: tool/component names)
- **Private files**: `01.5-custom.zsh`, `99-custom.zsh`, `dot-git-user`, `00-SECRETS.zsh` are git-ignored
- **New scripts**: Add to `bin/` — automatically on `$PATH` via `$DOTFILES_HOME/bin`
