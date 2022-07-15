#!/usr/bin/env bash

FOLDER_OPTS="--view=grid --display=folder --sort=name"

# dockutil --no-restart --remove all

# applications
dockutil --no-restart --add "/System/Applications/Calendar.app"
dockutil --no-restart --add "/System/Applications/Notes.app"
dockutil --no-restart --add "/Applications/Obsidian.app"
dockutil --no-restart --add "/Applications/Hey.app"
dockutil --no-restart --add "/Applications/Firefox Developer Edition.app"
dockutil --no-restart --add "/System/Applications/Messages.app"
dockutil --no-restart --add "/Applications/Discord.app"
dockutil --no-restart --add "/Applications/Slack.app"
dockutil --no-restart --add "/Applications/Sublime Merge.app"
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add "/System/Applications/System Preferences.app"

# folders
dockutil --no-restart --add /Downloads --replacing=Downloads --label=Downloads $FOLDER_OPTS
dockutil --no-restart --add /Applications --replacing=Applications --label=Applications --before=Downloads $FOLDER_OPTS
dockutil --no-restart --add ~/Pictures/screenshots --replacing=Screenshots --label=Screenshots --before=Downloads $FOLDER_OPTS

# restart dock
killall Dock