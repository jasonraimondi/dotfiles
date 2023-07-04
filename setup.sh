#!/usr/bin/env bash

set -euo pipefail

# Ask for the administrator password
sudo -v

# copy templates over if missing
[ ! -f git/dot-git-user ] && cp --no-clobber git/dot-git-user.template git/dot-git-user
[ ! -f zsh/dot-zsh/99-custom.zsh ] && echo "# add private zsh customizations here\n# this file is not included in git" > zsh/dot-zsh/99-custom.zsh

# configure mac system preferences
bash setup-systemprefs.sh

# install the more important stuff first
brew bundle --file brew/Requirefile --no-lock

# set symlinks using stow
bash setup-stow.sh

# Install applications using homebrew & casks
for BREWFILE in Brewfile Fontfile Caskfile Macfile; do
  brew bundle --file "brew/$BREWFILE" --no-lock
done

brew cleanup

bash setup-dock.sh

rtx install
rtx reshim

echo "✅ SUCCESS"
