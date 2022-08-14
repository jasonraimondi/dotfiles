# Brew

```bash
# Install applications using homebrew & casks
for BREWFILE in Brewfile Fontfile Caskfile Macfile; do
  brew bundle --file "brew/$BREWFILE" --no-lock
done
```
