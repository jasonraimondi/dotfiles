start=$(gdate +%s.%N)

for filename in $HOME/.zsh/**/*.zsh; do
  if [ $(basename "$filename") != "_main.zsh" ]; then
    source "$filename"
  fi 
done

end=$(gdate +%s.%N)

runtime=$(python -c "print(${end} - ${start})")

echo "dotfiles: $runtime ms"
