# Reload zsh config
alias setup!="bash $DOTFILES_HOME/setup.sh"
alias reload!='RELOAD=1 source ~/.zshrc'
alias redock!="bash $DOTFILES_HOME/setup-dock.sh"

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Dotfiles
alias dot="cd $DOTFILES_HOME"
alias edot="$GUI_EDITOR $DOTFILES_HOME"
alias cdot="code $DOTFILES_HOME"
alias gdot="smerge $DOTFILES_HOME"

# Default programs
alias stree="smerge"
alias rmine="rubymine"
alias storm="webstorm"
alias pstorm="phpstorm"
alias gland="goland"
function asdf() {
  echo "WARNING: Use rtx instead of asdf"
}

# Default options
alias mv="mv -i"
alias cp="cp -pi"
alias mkdir="mkdir -p"
alias rsync="rsync -vh"
alias json="json -c"
alias psgrep="psgrep -i"
alias df="df -H"
alias du="ncdu --color dark -rr -x --exclude .git --exclude node_modules"

# folder helpers
alias l="ls -lFh"     
alias ll="ls -lFh"    
alias lla="ls -lAFh"   
alias llr="ls -tRFh"   
alias llt="ls -ltFh"   
alias ldot="ls -ld .*"

# root
alias sudo="sudo "
alias root="sudo -i"

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
alias path='paths'

# Network
alias flushdns="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ipe="curl -s ipinfo.io | jq -r '.ip'"
alias ipl="ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'"

# Git
alias glog='git log --graph --pretty=format:"%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset" --abbrev-commit --date=relative'
alias gfa='git fetch --all --prune'

# Tmux
alias ta="tmux attach -t"
alias tn="tmux new -s"
alias tl="tmux list-sessions"
alias tls="tmux list-sessions"

# System
alias screenfetch="neofetch"
alias hdd="sudo hdparm -C /dev/sd[a-l]"

# Request using GET, POST, etc. method
for METHOD in GET HEAD POST PUT DELETE TRACE OPTIONS; do
  alias "$METHOD"="lwp-request -m '$METHOD'"
done
unset METHOD