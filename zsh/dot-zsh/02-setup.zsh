# homebrew computer club
if which brew > /dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# prefer mise by default, only use proto if USE_PROTO is set
if [[ "$USE_PROTO" == 1 ]]; then
  echo "using proto";
  export PROTO_HOME="$HOME/.proto";
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH";
elif command -v mise > /dev/null; then
  echo "using mise";
  eval "$(mise activate zsh)"
fi

if command -v fnox > /dev/null; then
  echo "using fnox";
  eval "$(fnox activate bash)"
fi

if command -v direnv > /dev/null; then
  eval "$(direnv hook zsh)"
fi

if command -v plan-bender > /dev/null; then
  eval "$(plan-bender completion zsh)"
fi
