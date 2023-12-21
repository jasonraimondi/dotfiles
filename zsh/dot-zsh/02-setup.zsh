# homebrew computer club
if which brew > /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# rtx language version manager
if which rtx > /dev/null; then
  eval "$(rtx activate zsh)"
  prepend_path "$HOME/.local/share/rtx/shims"
fi
