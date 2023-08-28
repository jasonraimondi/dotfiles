#!/usr/bin/env bash

stow -v -R --dotfiles aws
stow -v -R --dotfiles git
stow -v -R --dotfiles iterm2
stow -v -R --dotfiles mackup
stow -v -R --dotfiles ruby
stow -v -R --dotfiles rtx
stow -v -R --dotfiles tmux
stow -v -R --dotfiles vim
stow -v -R --dotfiles zsh
stow -v -t ~/.ssh ssh
stow -v -t ~/Library/Spelling dictionary
mkdir -p ~/.config && stow -v -t ~/.config config
