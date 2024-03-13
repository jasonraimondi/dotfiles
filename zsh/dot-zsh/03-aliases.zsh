# Reload zsh config
alias setup!="bash $DOTFILES_HOME/setup.sh"
alias stow!="cd ~/; bash $DOTFILES_HOME/setup-stow.sh; cd -"
alias reload!='RELOAD=1 source ~/.zshrc; mise reshim;'
alias redock!="bash $DOTFILES_HOME/setup-dock.sh"

# Default programs
function stree() {
  echo "WARNING: use smerge instead"
  force_learn_command "2024-03-01"
  smerge "$@"
}

# Dotfiles
alias dot="cd $DOTFILES_HOME"
alias edot="$GUI_EDITOR $DOTFILES_HOME"
alias cdot="code $DOTFILES_HOME"
alias gdot="smerge $DOTFILES_HOME"

# Default options
alias mv="mv -i"
alias cp="cp -pi"
alias mkdir="mkdir -p"
alias rsync="rsync -vh"
alias json="json -c"
alias psgrep="psgrep -i"
alias df="df -H"

# folder helpers
alias l="ls -lFh"     
alias ll="ls -lFh"    
alias lla="ls -lAFh"   
alias llr="ls -tRFh"   
alias llt="ls -ltFh"   
alias ldot="ls -ld .*"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"                  # Go to previous dir with -
alias cd.='cd $(readlink -f .)'    # Go to real dir (i.e. if current dir is linked)

# Reboot / Halt / Poweroff
alias reboot="sudo reboot"
alias poweroff="sudo poweroff"
alias halt="sudo halt"
alias shutdown="sudo shutdown"

# List declared aliases, functions, paths
alias aliases="alias | sed 's/=.*//'"
alias functions="declare -f | grep '^[a-z].* ()' | sed 's/{$//'"
alias paths='echo -e ${PATH//:/\\n}'

# Network
alias flushdns="dscacheutil -flushcache && killall -HUP mDNSResponder"
function ip() {
    local ip_address

    if [[ $1 == "local" ]]; then
        echo "local"
        ip_address=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    else
        ip_address=$(dig +short myip.opendns.com @resolver1.opendns.com)  
    fi

    if [ -z "$ip_address" ]; then
        echo "external using ipinfo.io"
        ip_address=$(curl -s ipinfo.io | jq -r '.ip')
    else
        echo "external using myip.opendns.com"
    fi

    echo $ip_address
}

# Git
alias glog='git log --graph --pretty=format:"%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'
alias gfa='git fetch --all --prune'

# Tmux
alias tls="tmux list-sessions"

# System
alias screenfetch="neofetch"
alias hdd="sudo hdparm -C /dev/sd[a-l]"
