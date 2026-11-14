# Sources the shell code a command prints, regenerating the cache when the
# command's binary changes. Nix store files all carry an mtime of 1970, so the
# cache is keyed on the binary's resolved path, which every upgrade changes.
function _source_cached() {
  local bin=$commands[$1] cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$1.zsh
  [[ -n $bin ]] || return 0
  local stamp="# ${bin:A}" first
  [[ -r $cache ]] && read -r first < $cache
  if [[ $first != $stamp ]]; then
    mkdir -p ${cache:h}
    { print -r -- $stamp && "$@" } >| $cache.$$ && mv -f $cache.$$ $cache || { rm -f $cache.$$; return 1 }
  fi
  source $cache
}

# atuin shell history
_source_cached atuin init zsh --disable-up-arrow
_source_cached direnv hook zsh
_source_cached mise completion zsh

unfunction _source_cached

# if command -v plan-bender > /dev/null; then
#   eval "$(plan-bender completion zsh)"
# fi
