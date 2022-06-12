# ASDF
if test -e $HOME/.asdf; then
    . $HOME/.asdf/asdf.sh
    
    # append completions to fpath
    fpath=(${ASDF_DIR}/completions $fpath)

    # initialise completions with ZSH's compinit
    autoload -Uz compinit && compinit

    # Hook direnv into your shell.
    eval "$(asdf exec direnv hook bash)"

    # A shortcut for asdf managed direnv.
    direnv() { asdf exec direnv "$@"; }
fi

# Golang
if test -e $HOME/Code/go; then
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
