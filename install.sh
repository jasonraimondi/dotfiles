#!/usr/bin/env bash

set -euo pipefail

# Ask for the administrator password
sudo -v

# run MacOS Software Update 
sudo softwareupdate --install --all --agree-to-license
sudo softwareupdate --install-rosetta --agree-to-license

# Accept XCode Stuff
# sudo xcodebuild -license accept

# Install XCode developer tools
# if ! command -v xcode-select &> /dev/null; then
#   sudo xcode-select --install
# fi

# Install homebrew from https://brew.sh
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make sure homebrew is sourced
eval "$(/opt/homebrew/bin/brew shellenv)"

# Clone this repository
_DOTFILE_PATH="${DOTFILE_PATH:-dotfiles}"
if [[ ! -d $_DOTFILE_PATH ]]; then
  git clone https://github.com/jasonraimondi/dotfiles.git $_DOTFILE_PATH
fi

cd $_DOTFILE_PATH

# Clone submodules to get deps
git submodule update --init --recursive

# bash setup.sh
