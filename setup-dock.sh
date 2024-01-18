#!/usr/bin/env bash

set -euo pipefail

dockutil --no-restart --remove all

# Array of application paths
applications=(
    "/Applications/Things.app"
    "/Applications/Obsidian.app"
    "/Applications/Discord.app"
    "/System/Applications/Messages.app"
    "/Applications/Slack.app"
    "/Applications/Polypane.app"
    "/Applications/Safari Technology Preview.app"
    "/Applications/Microsoft Edge.app"
    "/Applications/Firefox Developer Edition.app"
    "/System/Applications/Safari.app"
    "/Applications/Sublime Merge.app"
    "/Applications/Sublime Text.app"
    "$HOME/Applications/WebStorm.app"
    "$HOME/Applications/RubyMine.app"
    "$HOME/Applications/PyCharm Professional Edition.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/Linear.app"
    "/Applications/iTerm.app"
    "/Applications/Transmit.app"
    "/Applications/Proxyman.app"
    "/System/Applications/Music.app"
    "/System/Applications/System Settings.app"
    "/Applications/Keymapp.app"
)

# Loop through the array and apply dockutil
for app_path in "${applications[@]}"; do
    if [[ -e "$app_path" ]]; then
        dockutil --no-restart --add "$app_path"
    else
        echo "Application not found: $app_path"
    fi
done

# Folders
FOLDER_OPTS="--view=grid --display=folder --sort=name"

dockutil --no-restart --add ~/Downloads --replacing=Downloads --label=Downloads $FOLDER_OPTS
dockutil --no-restart --add /Applications --replacing=Applications --label=Applications --before=Downloads $FOLDER_OPTS
dockutil --no-restart --add ~/Pictures/screenshots --replacing=Screenshots --label=Screenshots --before=Downloads $FOLDER_OPTS

# Restart dock
killall Dock
