start=$(gdate +%s.%N)

export DOTFILES_HOME=$HOME/dotfiles

# Loop over all the *.zsh files in this directory
for filename in $HOME/.zsh/**/*.zsh; do
  # Do not reload the _main.zsh file
  if [ $(basename "$filename") != "_main.zsh" ]; then
    source "$filename"
  fi 
done

end=$(gdate +%s.%N)

runtime=$(echo "(${end} - ${start}) * 1000" | bc | xargs printf "%.0f")

echo "dotfiles in ${runtime}ms"
