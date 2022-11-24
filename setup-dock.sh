#!/usr/bin/env bash

set -euo pipefail

dockutil --no-restart --remove all

# applications
dockutil --no-restart --add "/Applications/Calendars.app"
dockutil --no-restart --add "/System/Applications/Reminders.app"
dockutil --no-restart --add "/System/Applications/Notes.app"
dockutil --no-restart --add "/Applications/Obsidian.app"
dockutil --no-restart --add "/Applications/Arc.app"
dockutil --no-restart --add "/Applications/Firefox Developer Edition.app"
dockutil --no-restart --add "/Applications/Brave Browser.app"
dockutil --no-restart --add "/Applications/Microsoft Edge.app"
dockutil --no-restart --add "/Applications/Safari.app"
dockutil --no-restart --add "/System/Applications/Messages.app"
dockutil --no-restart --add "/Applications/Discord.app"
dockutil --no-restart --add "/Applications/Slack.app"
# dockutil --no-restart --add "~/Applications/JetBrains Toolbox/WebStorm.app"
# dockutil --no-restart --add "~/Applications/JetBrains Toolbox/RubyMine.app"
dockutil --no-restart --add "/Applications/Sublime Merge.app"
dockutil --no-restart --add "/Applications/Visual Studio Code.app"
dockutil --no-restart --add "/Applications/iTerm.app"
dockutil --no-restart --add "/System/Applications/App Store.app"
dockutil --no-restart --add "/Applications/System Settings.app"

# folders
FOLDER_OPTS="--view=grid --display=folder --sort=name"

dockutil --no-restart --add ~/Downloads --replacing=Downloads --label=Downloads $FOLDER_OPTS
dockutil --no-restart --add /Applications --replacing=Applications --label=Applications --before=Downloads $FOLDER_OPTS
dockutil --no-restart --add ~/Pictures/screenshots --replacing=Screenshots --label=Screenshots --before=Downloads $FOLDER_OPTS

# restart dock
killall Dock