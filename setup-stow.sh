#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FLAGS=()
PREPARE_DIRS=1
for arg in "$@"; do
  case "$arg" in
    -D|--delete)
      FLAGS+=("-D")
      PREPARE_DIRS=0
      ;;
    -n|--dry-run)
      FLAGS+=("-n")
      PREPARE_DIRS=0
      ;;
  esac
done

prepare_dir() {
  if (( PREPARE_DIRS )); then
    if [[ "$1" == -m ]]; then
      install -d "$@"
    else
      mkdir -p "$@"
    fi
  elif [[ ! -d "${!#}" ]]; then
    echo "skipping: ${!#} does not exist" >&2
    return 1
  fi
}

stow ${FLAGS[@]+"${FLAGS[@]}"} aws
if prepare_dir "$HOME/.claude"; then
  stow ${FLAGS[@]+"${FLAGS[@]}"} claude
fi
stow ${FLAGS[@]+"${FLAGS[@]}"} git
if prepare_dir -m 700 "$HOME/.gnupg"; then
  stow ${FLAGS[@]+"${FLAGS[@]}"} -t "$HOME/.gnupg" gnupg
fi
stow ${FLAGS[@]+"${FLAGS[@]}"} iterm2
if prepare_dir "$HOME/Library/Spelling"; then
  stow ${FLAGS[@]+"${FLAGS[@]}"} -t "$HOME/Library/Spelling" dictionary
fi
stow ${FLAGS[@]+"${FLAGS[@]}"} mise
stow ${FLAGS[@]+"${FLAGS[@]}"} ruby
stow ${FLAGS[@]+"${FLAGS[@]}"} tmux
stow ${FLAGS[@]+"${FLAGS[@]}"} vim
stow ${FLAGS[@]+"${FLAGS[@]}"} zsh
stow ${FLAGS[@]+"${FLAGS[@]}"} zprezto
if prepare_dir "$HOME/.config/herdr" "$HOME/.config/herdr-app"; then
  stow ${FLAGS[@]+"${FLAGS[@]}"} --ignore='herdr/(?!config\.toml$).*' -t "$HOME/.config" config
fi
if prepare_dir -m 700 "$HOME/.ssh"; then
  stow ${FLAGS[@]+"${FLAGS[@]}"} -t "$HOME/.ssh" ssh
fi
