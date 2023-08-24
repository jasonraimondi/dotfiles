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

if command -v podman &> /dev/null; then
    prepend_path "$HOME/.local/share/containers/podman-desktop/extensions-storage/podman-desktop.compose/bin"
fi

test -e $HOME/.cargo/bin && append_path "$HOME/.cargo/bin";

# K8s
test -e $HOME/.krew/bin && append_path "$HOME/.krew/bin";

# Minio
test -e /usr/local/bin/mc && complete -o nospace -C /usr/local/bin/mc mc;

# iTerm2
test -e $HOME/.iterm2_shell_integration.zsh && source "$HOME/.iterm2_shell_integration.zsh"
