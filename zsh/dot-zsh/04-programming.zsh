append_path "/Users/$USER/Library/Application Support/JetBrains/Toolbox/scripts"

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Golang
if command -v go &> /dev/null; then
    export GO111MODULE=on; 
    export GOPATH="$HOME/Code/go"; 
    prepend_path "/usr/local/go/bin"
fi

# K8s
test -e $HOME/.krew/bin && append_path "$HOME/.krew/bin";

# Minio
test -e /usr/local/bin/mc && complete -o nospace -C /usr/local/bin/mc mc;

# iTerm2
test -e $HOME/.iterm2_shell_integration.zsh && source "$HOME/.iterm2_shell_integration.zsh"
