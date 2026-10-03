# Brew

```bash
# Install applications using homebrew & casks
for BREWFILE in Requirefile Brewfile Fontfile Caskfile CaskfileQuicklook CaskfileExtended Macfile; do
  brew bundle --file "brew/$BREWFILE"
done
```
