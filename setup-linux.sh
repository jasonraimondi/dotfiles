#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

function install_packages() {
  if command -v apt-get > /dev/null; then
    sudo apt-get update && sudo apt-get install -y "$@"
  elif command -v dnf > /dev/null; then
    sudo dnf install -y "$@"
  elif command -v pacman > /dev/null; then
    sudo pacman -S --needed --noconfirm "$@"
  else
    echo "no supported package manager found, install these yourself: $*" >&2
    exit 1
  fi
}

missing=()
for cmd in zsh stow git; do
  command -v "$cmd" > /dev/null || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
  install_packages "${missing[@]}"
fi

git submodule update --init --recursive zprezto/dot-zprezto

[ ! -f zsh/dot-zsh/99-custom.zsh ] && printf '# add private zsh customizations here\n# this file is not included in git\n' > zsh/dot-zsh/99-custom.zsh

for pkg in zsh zprezto; do
  for src in "$pkg"/dot-*; do
    target="$HOME/.${src#"$pkg"/dot-}"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      mv -n "$target" "$target.pre-dotfiles"
    fi
  done
done

stow -t "$HOME" zsh zprezto

ZSH_PATH="$(command -v zsh)"
USER_NAME="$(id -un)"
if [ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "$ZSH_PATH" ]; then
  sudo chsh -s "$ZSH_PATH" "$USER_NAME"
fi

echo "✅ SUCCESS"
