# homebrew computer club
if which brew > /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v direnv > /dev/null; then
  eval "$(direnv hook zsh)"
fi

# mise is the global default; proto is opt-in per-directory via direnv
# (see ~/Code/intelligems/.envrc). PROTO_HOME is exported so .envrc can reuse it.
export PROTO_HOME="$HOME/.proto"

if command -v mise > /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v fnox > /dev/null; then
  echo "using fnox";
  eval "$(fnox activate bash)"
fi

if command -v plan-bender > /dev/null; then
  eval "$(plan-bender completion zsh)"
fi
