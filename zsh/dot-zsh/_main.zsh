for filename in $HOME/.zsh/**/*.zsh; do
  if [ $(basename "$filename") != "_main.zsh" ]; then
    source "$filename"
  fi 
done
