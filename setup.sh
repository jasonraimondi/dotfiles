#!/usr/bin/env bash

set -euo pipefail

# Ask for the administrator password
sudo -v

# copy templates over if missing
[ ! -f git/dot-git-user ] && cp -n git/dot-git-user.template git/dot-git-user
[ ! -f zsh/dot-zsh/99-custom.zsh ] && printf '# add private zsh customizations here\n# this file is not included in git\n' > zsh/dot-zsh/99-custom.zsh

# configure mac system preferences
bash setup-systemprefs.sh

# install the more important stuff first
brew bundle --file brew/Requirefile

# set symlinks using stow
bash setup-stow.sh

# Install applications using homebrew & casks
for BREWFILE in Brewfile Fontfile Caskfile CaskfileQuicklook Macfile; do
  brew bundle --file "brew/$BREWFILE"
done

brew cleanup

bash setup-dock.sh

export PATH="$HOME/.local/bin:$PATH"
command -v mise > /dev/null || curl -fsSL https://mise.run | sh
mise install --yes
mise reshim

echo "✅ SUCCESS"
