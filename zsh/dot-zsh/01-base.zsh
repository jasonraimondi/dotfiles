setopt EXTENDED_HISTORY # add timestamps to history

# Dotfiles Bin Directory
test -e $DOTFILES_HOME/bin && PATH="$PATH:$DOTFILES_HOME/bin"
