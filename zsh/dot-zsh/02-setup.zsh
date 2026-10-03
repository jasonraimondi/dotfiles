# homebrew computer club
if which brew > /dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v mise > /dev/null 2>&1; then
  eval "$(mise completion zsh)"
fi

if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi

# if command -v plan-bender > /dev/null; then
#   eval "$(plan-bender completion zsh)"
# fi
