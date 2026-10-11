zmodload zsh/datetime
start=$EPOCHREALTIME

export DOTFILES_HOME=$HOME/dotfiles

# Loop over all the *.zsh files in this directory
for filename in $HOME/.zsh/**/*.zsh; do
  # Do not reload the _main.zsh file
  if [ $(basename "$filename") != "_main.zsh" ]; then
    source "$filename"
  fi 
done

printf "dotfiles in %.0fms\n" $(( (EPOCHREALTIME - start) * 1000 ))
