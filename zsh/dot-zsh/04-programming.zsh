if [[ "$OSTYPE" == darwin* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
fi
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PATH:$PNPM_HOME" ;;
esac
case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) export PATH="$PATH:$PNPM_HOME/bin" ;;
esac
