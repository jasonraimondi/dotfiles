---
name: dotfiles
description: Change Jason's macOS dotfiles in ~/dotfiles. Use when asked to add or change a shell alias, function, env var, PATH entry, tool init, Homebrew package, mise tool version, git alias or setting, macOS default, Dock app, or an app config under ~/.config (herdr, zed, karabiner, mise), or to add a script to bin.
---

# Dotfiles

`~/dotfiles` is a GNU Stow repo. Every top-level directory is a package stowed into `$HOME`; `dot-foo` becomes `~/.foo`. Edit the file in the repo, never the symlink target in `$HOME`.

## Steps

1. **Route.** Pick the file from the table below. One concern, one file. When the change fits no row, say so and propose the file before editing.
2. **Edit** in `~/dotfiles`. Match the neighbouring style. Guard a tool init with `command -v` the way `02-setup.zsh` does.
3. **Verify** with the command for that row. Done when it exits 0 and the new thing resolves.
4. **Apply.** A new file in an existing package needs `bash setup-stow.sh -n` then `bash setup-stow.sh`. A conflict means a real file sits where a symlink belongs: stop and report it, never `--adopt`. An edit to an existing file needs nothing; tell the user `exec zsh` for shell changes.
5. **Commit** to `main` as `type(scope): description`. Scope is the package directory, or the app name under `config/`. `git status --short` first: Herdr writes runtime files into `config/herdr/` through the folded symlink, so stage only your change.

## Routing

| Change | File | Verify |
|---|---|---|
| general alias | `zsh/dot-zsh/03-aliases.zsh` | `zsh -i -c 'whence -w NAME'` reports `alias` |
| macOS alias | `zsh/dot-zsh/03-aliases-macos.zsh` | same |
| dev or AI tool alias (`claude`, `opus`, `fable` live here) | `zsh/dot-zsh/03-aliases-programming.zsh` | same |
| function | `zsh/dot-zsh/05-functions.zsh`; git ones in `05-functions-git.zsh` | `whence -w` reports `function`; `return`, never `exit` |
| env var | `zsh/dot-zsh/01-exports.zsh` | `zsh -i -c 'echo $NAME'` |
| PATH entry | `zsh/dot-zsh/01-base.zsh` via `prepend_path` | `zsh -i -c 'echo $PATH'` |
| tool init (`eval "$(x init zsh)"`) | `zsh/dot-zsh/02-setup.zsh` | `zsh -i -c exit` exits 0 |
| script | `bin/NAME`, `#!/usr/bin/env bash`, `set -euo pipefail`, `chmod +x` | `shellcheck bin/NAME` |
| CLI formula | `brew/Brewfile` | `brew info NAME` resolves |
| GUI app | `brew/Caskfile`; hobby or optional apps in `CaskfileExtended` (manual install only) | `brew info --cask NAME` |
| font | `brew/Fontfile` | same |
| Mac App Store app | `brew/Macfile` | `mas search NAME` |
| language or tool version | `config/mise/config.toml` | `mise ls` |
| default npm or gem package | `mise/dot-default-npm-packages`, `mise/dot-default-gems` | file read |
| git alias or setting | `git/dot-gitconfig` | `git config --get KEY` |
| global gitignore | `git/dot-gitignore` | `git check-ignore -v PATH` |
| Herdr, Zed, Karabiner | `config/APP/` | app reload |
| macOS default | `setup-systemprefs.sh` with the `run` wrapper | `bash setup-systemprefs.sh -n` |
| Dock app | `setup-dock.sh` | `bash setup-dock.sh` |
| tmux, vim | `tmux/dot-tmux.conf`, `vim/dot-vimrc` | `tmux source-file`, `vim -c q` |
| new package | new directory plus a line in `setup-stow.sh` | `bash setup-stow.sh -n` |

Shell files load alphabetically, so `03-aliases-*.zsh` run before `03-aliases.zsh` and an alias defined later wins over an earlier function of the same name. Check `whence -w` after every alias or function.

Mise is not activated globally, only its completions load. A tool added to `config/mise/config.toml` is on PATH only where a project activates mise.

## Private files

`zsh/dot-zsh/99-custom.zsh` and `01.5-custom.zsh` are gitignored per-machine files. Edit them only when asked for a private or local change, and skip the commit step.

Never read, edit, or print `zsh/dot-zsh/00-SECRETS.zsh`, `git/dot-git-user`, `aws/dot-aws/*`, `ssh/config`, or any `.gpg` file.
