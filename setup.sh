#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Ask for the administrator password
sudo -v

# copy templates over if missing
[ ! -f git/dot-git-user ] && cp -n git/dot-git-user.template git/dot-git-user
[ ! -f zsh/dot-zsh/99-custom.zsh ] && printf '# add private zsh customizations here\n# this file is not included in git\n' > zsh/dot-zsh/99-custom.zsh

# Homebrew, the system preferences and the Dock are macOS only; Linux gets
# just the Nix half: links, command-line tools and mise.
is_darwin() { [ "$(uname)" = Darwin ]; }

if is_darwin; then
  bash setup-systemprefs.sh

  # brew is not on PATH in a fresh shell
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$brew_bin" ]; then
      eval "$("$brew_bin" shellenv)"
      break
    fi
  done

  # install the more important stuff first
  brew bundle --file brew/Requirefile
fi

git config core.hooksPath .githooks

# nix builds the Home Manager generation that setup-home.sh links into $HOME
[ -x /nix/var/nix/profiles/default/bin/nix ] || curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
bash setup-home.sh

# the Home Manager profile holds dockutil and mise, which the steps below call
export PATH="$HOME/.nix-profile/bin:$PATH"

if is_darwin; then
  # Install applications using homebrew & casks
  for BREWFILE in Brewfile Fontfile Caskfile CaskfileQuicklook Macfile; do
    brew bundle --file "brew/$BREWFILE"
  done

  brew cleanup

  bash setup-dock.sh
fi

mise install --yes
mise reshim

echo "✅ SUCCESS"
