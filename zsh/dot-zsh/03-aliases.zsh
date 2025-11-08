# Reload zsh config
alias setup!="bash $DOTFILES_HOME/setup.sh"
alias stow!="cd ~/; bash $DOTFILES_HOME/setup-stow.sh; cd -"
alias reload!="exec $SHELL"
alias redock!="bash $DOTFILES_HOME/setup-dock.sh"

# Default programs
function stree() {
  echo "WARNING: use smerge instead"
  force_learn_command "2024-03-01"
  smerge "$@"
}

# Dotfiles
alias dot="cd $DOTFILES_HOME"
alias cdot="zed $DOTFILES_HOME"
alias cfunc="subl $DOTFILES_HOME/zsh/dot-zsh/99-custom.zsh"
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
alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"
alias dnsflush="echo 'use flushdns' && flushdns"

# Git
alias glog='git log --graph --pretty=format:"%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'
alias gfa='git fetch --all --prune'

# Tmux
alias tls="tmux list-sessions"

# System
alias screenfetch="neofetch"
alias hdd="sudo hdparm -C /dev/sd[a-l]"

alias speedtest="networkQuality -v -s"
