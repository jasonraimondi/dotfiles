# ASDF
if test -e $HOME/.asdf; then
    . $HOME/.asdf/asdf.sh
    # append completions to fpath
    fpath=(${ASDF_DIR}/completions $fpath)
    # initialise completions with ZSH's compinit
    autoload -Uz compinit && compinit
fi

# Golang
if test -e $HOME/Code/go; then
    export GOPATH=${HOME}/Code/go; 
    export GO111MODULE=on; 
    export PATH=$PATH:/usr/local/go/bin
fi

# K8s
test -e $HOME/.krew/bin && export PATH="$HOME/.krew/bin:$PATH";

# Minio
test -e /usr/local/bin/mc && complete -o nospace -C /usr/local/bin/mc mc;
