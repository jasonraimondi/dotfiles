export GPG_TTY=$(tty)

# Dotfiles Bin Directory
test -e $HOME/dotfiles/bin && PATH="$PATH:$HOME/dotfiles/bin"

# iTerm2
test -e $HOME/.iterm2_shell_integration.zsh && source "${HOME}/.iterm2_shell_integration.zsh"

setopt EXTENDED_HISTORY # add timestamps to history
