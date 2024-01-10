# homebrew computer club
if which brew > /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# mise language version manager
if which mise > /dev/null; then
  eval "$(mise activate zsh)"
  prepend_path "$HOME/.local/share/mise/shims"
fi
