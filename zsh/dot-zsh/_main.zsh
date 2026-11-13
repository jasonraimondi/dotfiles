zmodload zsh/datetime
_dotfiles_start=$EPOCHREALTIME

for _dotfiles_file in $HOME/.zsh/[0-9]*.zsh; do
  source $_dotfiles_file
done

# Only on a terminal, so `zsh -i -c '...'` output stays clean for tools.
if [[ -t 1 && -z $ZSH_EXECUTION_STRING ]]; then
  printf "dotfiles in %.0fms\n" $(( (EPOCHREALTIME - _dotfiles_start) * 1000 ))
fi
unset _dotfiles_start _dotfiles_file
