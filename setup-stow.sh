#!/usr/bin/env bash

FLAGS=""
for arg in "$@"; do
  case "$arg" in
    -D|--delete) FLAGS="$FLAGS -D" ;;
    -n|--dry-run) FLAGS="$FLAGS -n" ;;
  esac
done

stow $FLAGS aws
mkdir -p ~/.config && stow $FLAGS -t ~/.config config
stow $FLAGS git
stow $FLAGS iterm2
stow $FLAGS -t ~/Library/Spelling dictionary
stow $FLAGS mackup
stow $FLAGS mise
stow $FLAGS ruby
mkdir -p ~/.ssh && stow $FLAGS -t ~/.ssh ssh
stow $FLAGS tmux
stow $FLAGS vim
stow $FLAGS zsh
stow $FLAGS zprezto
