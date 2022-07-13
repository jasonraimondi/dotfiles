#!/usr/bin/env bash

# How to Allow Apps from Anywhere in Gatekeeper
sudo spctl --master-disable

# Show the ~/Library and /Volumes folder
chflags nohidden ~/Library
sudo chflags nohidden /Volumes

# Set a really fast key repeat.
defaults write -g KeyRepeat -int 2

# Sets a pretty fast initial wait for key repeat, to block dup keysends
defaults write -g InitialKeyRepeat -int 25

# Set the Finder prefs for showing a few different volumes on the Desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Save to disk by default, instead of iCloud
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Set the date format in the OSX Bar
defaults write com.apple.menuextra.clock "DateFormat" "EEE d MMM h:mm:ss a"

# Set the battery percent
defaults write com.apple.menuextra.battery ShowPercent YES

# For the UI settings to take effect
killall SystemUIServer

# Set the dock preferences size
defaults write com.apple.dock tilesize -int 60

# Set the dock to autohide and the speed to really fast
defaults read com.apple.Dock autohide
defaults write com.apple.Dock autohide-delay -float 0.0001
defaults write com.apple.dock autohide-time-modifier -float 0.25
defaults write com.apple.dock tilesize -float 42.0
killall Dock

# Power set display sleep 3h on adapter, 10m on battery
sudo pmset sleep 0
sudo pmset -a displaysleep 180
sudo pmset -b displaysleep 10

# Set up Safari for development.
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Run the screensaver if we're in the bottom-left hot corner.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Screen saver password lock
# /usr/bin/profiles -I -F askforpassworddelay.config

# Change screenshot save destination to ~/Pictures/screenshots
mkdir -p ~/Pictures/screenshots
defaults write com.apple.screencapture location ~/Pictures/screenshots
# Remove screenshot from screenshot filename
defaults write com.apple.screencapture name ""
# Change screenshot save format to png
defaults write com.apple.screencapture type png
# Do not include shadows in screenshots
defaults write com.apple.screencapture disable-shadow -bool true
killall SystemUIServer

# Update Rectangle.app's default config to spectacle
# If you wish to change the default shortcuts after first launch, use the following command.
# True is for the recommended shortcuts, false is for Spectacle's.
defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true