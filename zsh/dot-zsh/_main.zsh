start=$(gdate +%s.%N)

export DOTFILES_HOME=$HOME/dotfiles

if test -e /opt/homebrew/bin/brew; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Loop over all the *.zsh files in this directory
for filename in $HOME/.zsh/**/*.zsh; do
  # Do not reload the _main.zsh file
  if [ $(basename "$filename") != "_main.zsh" ]; then
    source "$filename"
  fi 
done

end=$(gdate +%s.%N)

runtime=$(python -c "print(${end} - ${start})")

echo "dotfiles: $runtime"
