#!/usr/bin/env bash

set -euo pipefail

# Ask for the administrator password
sudo -v

# Install homebrew from https://brew.sh
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make sure homebrew is sourced
eval "$(/opt/homebrew/bin/brew shellenv)"

# run MacOS Software Update 
sudo softwareupdate -i -a

# Accept XCode Stuff
sudo xcodebuild -license accept
#sudo softwareupdate --install-rosetta

# Install xcode developer tools
if ! command -v xcode-select &> /dev/null; then
  sudo xcode-select --install
fi

# Clone this repository
_DOTFILE_PATH="${DOTFILE_PATH:-dotfiles}"
if [[ ! -d $_DOTFILE_PATH ]]; then
  git clone git@github.com:jasonraimondi/dotfiles.git $_DOTFILE_PATH
fi

cd $_DOTFILE_PATH

# Clone submodules to get deps
git submodule update --init --recursive

# bash setup.sh
