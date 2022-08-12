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

# broken until this gets fixed:
#   https://github.com/Homebrew/homebrew-core/pull/97394
# bash setup-dock.sh

# Install applications using homebrew & casks
for BREWFILE in Brewfile Fontfile Caskfile Macfile; do
  brew bundle --file "brew/$BREWFILE" --no-lock
done

brew cleanup

# Install
if ! test -e $HOME/.asdf; then
  ASDF_VERSION=$(curl -sL https://api.github.com/repos/asdf-vm/asdf/releases/latest | jq -r ".tag_name")
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "$ASDF_VERSION"
  unset ASDF_VERSION;
fi

asdf update

# Install ASDF plugins
for PLUGIN in deno direnv elixir erlang golang nodejs php pnpm python ruby rust; do
  asdf plugin-add "$PLUGIN" || true
done

asdf plugin update --all
asdf install

echo "✅ SUCCESS"
