# add timestamps to history
setopt EXTENDED_HISTORY

function prepend_path() {
  [[ ! -d "$1" ]] && return

  path=(
      $1
      $path
  )
}

function append_path() {
  [[ ! -d "$1" ]] && return

  path=(
      $path
      $1
  )
}

# add bin repository
prepend_path "$DOTFILES_HOME/bin"
prepend_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
prepend_path "$HOME/.local/bin"
