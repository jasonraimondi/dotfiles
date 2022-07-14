#!/usr/bin/env bash

set -euo pipefail

# Ask for the administrator password
sudo -v

# First, clone submodules to get deps like zprezto
git submodule update --init --recursive

# make sure homebrew is sourced
eval "$(/opt/homebrew/bin/brew shellenv)"

# copy templates over if missing
[ ! -f git/dot-git-user ] && cp git/git-user.template git/dot-git-user

# configure mac system preferences
bash setup-systemprefs.sh

# install the more important stuff first
brew bundle --file brew/Requirefile --no-lock

# set symlinks using stow
bash setup-stow.sh

# run MacOS Software Update 
sudo softwareupdate -i -a

# Accept XCode Stuff
sudo xcodebuild -license accept
#sudo softwareupdate --install-rosetta

function set_dock_icons() {
  local FOLDER_OPTS="--view=grid --display=folder --sort=name"
  dockutil --add /Applications --replacing=Applications --before=Downlasdfoads --label=Applications $FOLDER_OPTS
  dockutil --add ~/Pictures/screenshots --replacing=Screenshots --before=Downloads --label=Screenshots $FOLDER_OPTS
}

# broken until this gets fixed:
#   https://github.com/Homebrew/homebrew-core/pull/97394
# set_dock_icons

# Install xcode developer tools
if ! command -v xcode-select &> /dev/null; then
  sudo xcode-select --install
fi

# Install homebrew from https://brew.sh
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

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
for PLUGIN in deno direnv elixir erlang golang nodejs php python ruby rust; do
  asdf plugin-add "$PLUGIN" || true
done

asdf plugin update --all
asdf install

echo "✅ SUCCESS"
