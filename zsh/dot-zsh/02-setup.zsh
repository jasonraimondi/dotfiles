# homebrew computer club
if which brew > /dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# atuin shell history
if which atuin > /dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v direnv > /dev/null 2>&1; then
  eval "$(direnv hook zsh)"

  # direnv 2.38.1 skips its hook unless ZSH_EVAL_CONTEXT starts with "toplevel",
  # which never holds inside precmd, so .envrc only loaded after a cd.
  direnv_hook_stock=${functions[_direnv_hook]}
  functions[_direnv_hook]=${direnv_hook_stock/'$ZSH_EVAL_CONTEXT != toplevel(:[a-z]#func|)#'/'$ZSH_EVAL_CONTEXT == *cmdsubst*'}
  if [[ ${functions[_direnv_hook]} != "$direnv_hook_stock" ]]; then
    echo "WORKAROUND: patched direnv $(direnv version) zsh hook; remove from 02-setup.zsh once https://github.com/direnv/direnv/issues/1633 is fixed"
  fi
  unset direnv_hook_stock
fi

if command -v mise > /dev/null 2>&1; then
  eval "$(mise completion zsh)"
fi

if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi

# if command -v plan-bender > /dev/null; then
#   eval "$(plan-bender completion zsh)"
# fi
