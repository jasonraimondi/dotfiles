# add timestamps to history
setopt EXTENDED_HISTORY

# add bin repository
test -e $DOTFILES_HOME/bin && PATH="$PATH:$DOTFILES_HOME/bin"
