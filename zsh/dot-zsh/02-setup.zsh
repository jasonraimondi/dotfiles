# homebrew computer club
if which brew > /dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# shims rather than `mise activate`: its per-prompt PATH rebuild fights direnv,
# which hands ~/Code/intelligems/intelligems over to proto
if command -v mise > /dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
  eval "$(mise completion zsh)"
fi

# if command -v plan-bender > /dev/null; then
#   eval "$(plan-bender completion zsh)"
# fi
