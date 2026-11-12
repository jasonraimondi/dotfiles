#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Ask for the administrator password
sudo -v

# copy templates over if missing
[ ! -f git/dot-git-user ] && cp -n git/dot-git-user.template git/dot-git-user
[ ! -f zsh/dot-zsh/99-custom.zsh ] && printf '# add private zsh customizations here\n# this file is not included in git\n' > zsh/dot-zsh/99-custom.zsh

# configure mac system preferences
bash setup-systemprefs.sh

# brew is not on PATH in a fresh shell
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done

git submodule update --init --recursive

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

mise install --yes
mise reshim

echo "✅ SUCCESS"
