zmodload -F zsh/stat b:zstat

# Sources the shell code a command prints, regenerating the cache when the
# command's binary changes. Brew relinks on upgrade but keeps the bottle's build
# mtime on the binary, so the link's own mtime is compared as well as the target's.
function _source_cached() {
  local bin=$commands[$1] cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/$1.zsh
  [[ -n $bin ]] || return 0
  local -a cached=(0) link target
  [[ -s $cache ]] && zstat -A cached +mtime -- $cache
  zstat -L -A link +mtime -- $bin
  zstat -A target +mtime -- $bin
  if (( link[1] > cached[1] || target[1] > cached[1] )); then
    mkdir -p ${cache:h}
    "$@" >| $cache.$$ && mv -f $cache.$$ $cache || { rm -f $cache.$$; return 1 }
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
