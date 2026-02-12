#!/usr/bin/env bash

FLAGS=""
for arg in "$@"; do
  case "$arg" in
    -D|--delete) FLAGS="$FLAGS -D" ;;
    -n|--dry-run) FLAGS="$FLAGS -n" ;;
  esac
done

stow $FLAGS aws
stow $FLAGS git
stow $FLAGS iterm2
stow $FLAGS -t ~/Library/Spelling dictionary
stow $FLAGS mackup
stow $FLAGS mise
stow $FLAGS ruby
stow $FLAGS tmux
stow $FLAGS vim
stow $FLAGS zsh
stow $FLAGS zprezto
mkdir -p ~/.config \
  && stow $FLAGS -t ~/.config config
mkdir -p ~/.ssh \
  && stow $FLAGS -t ~/.ssh ssh


# AI

mkdir -p ~/.claude \
  && ln -sf ai/AGENT.md ~/.claude/CLAUDE.md
mkdir -p ~/.cursor/rules \
  && ln -sf ai/AGENT.md ~/.cursor/rules/agent.md
mkdir -p ~/.codeium/windsurf/memories \
  && ln -sf ai/AGENT.md ~/.codeium/windsurf/memories/global_rules.md
mkdir -p ~/.junie \
  && ln -sf ai/AGENT.md ~/.junie/guidelines.md
mkdir -p ~/.pi/agent \
  && ln -sf ai/AGENT.md ~/.pi/agent/AGENT.md
