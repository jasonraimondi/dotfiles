#!/bin/bash

# Exit on any error
set -e

# Store the current directory
REPO_ROOT=$(git rev-parse --show-toplevel)

# Function to remove a submodule completely
remove_submodule() {
    local path="$1"
    echo "Removing submodule at $path..."
    
    # Remove the submodule entry from .git/config
    git submodule deinit -f "$path"
    
    # Remove the submodule from .git/modules
    rm -rf "$REPO_ROOT/.git/modules/$path"
    
    # Remove the submodule directory
    rm -rf "$path"
    
    # Remove the submodule entry from .gitmodules
    git config -f .gitmodules --remove-section "submodule.$path" || true
    
    # Remove the submodule entry from .git/config
    git config -f .git/config --remove-section "submodule.$path" || true
    
    # Stage the .gitmodules changes
    git add .gitmodules
    
    # Stage the submodule directory removal
    git add "$path"
}

# Function to add a submodule
add_submodule() {
    local path="$1"
    local url="$2"
    echo "Adding submodule $url at $path..."
    
    # Create the parent directory if it doesn't exist
    mkdir -p "$(dirname "$path")"
    
    # Add the submodule
    git submodule add "$url" "$path"
}

# Backup .gitmodules
cp .gitmodules .gitmodules.backup

# Remove existing submodules
remove_submodule "zprezto/dot-zprezto"
remove_submodule "tmux/dot-tmux/plugins/tmux"
remove_submodule "tmux/dot-tmux/plugins/tmux-resurrect"
remove_submodule "tmux/dot-tmux/plugins/tmux-sensible"
remove_submodule "tmux/dot-tmux/plugins/tpm"
remove_submodule "vim/dot-vim/pack/themes/start/dracula"

# Commit the removal
git commit -m "Remove all submodules for refresh"

# Add submodules back
add_submodule "zprezto/dot-zprezto" "https://github.com/sorin-ionescu/prezto.git"
add_submodule "tmux/dot-tmux/plugins/tmux" "https://github.com/dracula/tmux"
add_submodule "tmux/dot-tmux/plugins/tmux-resurrect" "https://github.com/tmux-plugins/tmux-resurrect"
add_submodule "tmux/dot-tmux/plugins/tmux-sensible" "https://github.com/tmux-plugins/tmux-sensible"
add_submodule "tmux/dot-tmux/plugins/tpm" "https://github.com/tmux-plugins/tpm"
add_submodule "vim/dot-vim/pack/themes/start/dracula" "https://github.com/dracula/vim.git"

# Initialize and update all submodules
git submodule update --init --recursive

# Commit the new submodules
git commit -m "Re-add all submodules with latest commits"

echo "All submodules have been refreshed successfully!"
