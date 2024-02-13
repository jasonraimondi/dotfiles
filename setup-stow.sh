#!/usr/bin/env bash

stow -v -R --dotfiles aws
mkdir -p ~/.config && stow -v -t ~/.config config
stow -v -R --dotfiles git
stow -v -R --dotfiles iterm2
stow -v -t ~/Library/Spelling dictionary
stow -v -R --dotfiles mackup
stow -v --dotfiles mise
stow -v -R --dotfiles ruby
stow -v -t ~/.ssh ssh
stow -v -R --dotfiles tmux
stow -v -R --dotfiles vim
stow -v -R --dotfiles zsh
stow -v -R --dotfiles zprezto

