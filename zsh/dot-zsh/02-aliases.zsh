# reload zsh config
alias reload!='RELOAD=1 source ~/.zshrc'


alias jr="cd ~/Code/jasonraimondi/jasonraimondi"
alias jcp="cd ~/Code/jasonraimondi/jasonraimondi"

alias stree="smerge"
alias vim="nvim"
# alias cat="bat -p"

# folder helpers
alias l="ls -lFh"     #size,show type,human readable
alias lla="ls -lAFh"   #long list,show almost all,show type,human readable
alias llr="ls -tRFh"   #sorted by date,recursive,show type,human readable
alias llt="ls -ltFh"   #long list,sorted by date,show type,human readable
alias ll="ls -lFh"    #long list
alias ldot="ls -ld .*"
alias mv="mv -i"
alias cp="cp -pi"
alias mkdir="mkdir -p"

# become root #
alias sudo="sudo "
alias root="sudo -i"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../../"

# reboot / halt / poweroff
alias reboot="sudo reboot"
alias poweroff="sudo poweroff"
alias halt="sudo halt"
alias shutdown="sudo shutdown"

## set some other defaults ##
alias df="df -H"
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"

# Git
alias glog='git log --graph --pretty=format:"%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'
alias gaa="git add . "
alias gcm="git commit -m "
alias gb="git branch"
alias gfa='git fetch --all --prune'

# Tmux
alias ta="tmux attach -t"
alias tn="tmux new -s"
alias tl="tmux list-sessions"
alias tls="tmux list-sessions"

# Dotfiles
alias dot="cd ~/dotfiles"
alias sdot="subl ~/dotfiles"
alias cdot="code ~/dotfiles"

# System
alias screenfetch="neofetch"
alias hdd="sudo hdparm -C /dev/sd[a-l]"
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"


alias serve="ruby -run -e httpd . -p 8000"

