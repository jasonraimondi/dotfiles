#!/usr/bin/env bash

set -euo pipefail

# Ask for the administrator password
sudo -v

# Installs all available software updates for MacOS.
sudo softwareupdate --install --all --agree-to-license

# Rosetta is necessary on Apple Silicon Macs to run applications compiled for Intel x86_64 architecture
# sudo softwareupdate --install-rosetta --agree-to-license

# Install XCode developer tools
if ! xcode-select -p &>/dev/null; then
    echo "Command Line Developer Tools not found. Installing..."
    # Trigger the Command Line Tools installation prompt
    xcode-select --install
    
    # Wait until the Command Line Tools are installed
    until xcode-select -p &>/dev/null; do
        echo "Waiting for Command Line Developer Tools to finish installing..."
        sleep 5
    done
    
    echo "Command Line Developer Tools installed successfully."
else
    echo "Command Line Developer Tools are already installed."
fi

# Install homebrew from https://brew.sh
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make sure homebrew is sourced
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install mas to get xcode
brew install mas

# This is xcode, mas search xcode, mas lucky xcode
mas install 497799835

# Accept XCode Stuff
sudo xcodebuild -license accept

# Clone this repository
_DOTFILE_PATH="${DOTFILE_PATH:-dotfiles}"
if [[ ! -d $_DOTFILE_PATH ]]; then
  git clone https://github.com/jasonraimondi/dotfiles.git $_DOTFILE_PATH
fi

cd $_DOTFILE_PATH

# Clone submodules to get deps
git submodule update --init --recursive

# bash setup.sh
