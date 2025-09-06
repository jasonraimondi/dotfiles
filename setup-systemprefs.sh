#!/usr/bin/env bash

# macOS Setup Script - Updated and Validated for macOS Sequoia (15.x)
# Last updated: September 2025
# Tested on: macOS Sequoia 15.0+

echo "Starting macOS setup script for Sequoia..."

# ========================================
# SECURITY SETTINGS
# ========================================

# Gatekeeper - CHANGED in Sequoia: Command alone no longer works
# Now requires manual confirmation in System Settings
echo "Setting up Gatekeeper (requires manual confirmation in System Settings)..."
sudo spctl --master-disable
echo "⚠️  IMPORTANT: Go to System Settings > Privacy & Security and manually select 'Anywhere' option"
echo "   This is required in macOS Sequoia and cannot be automated via command line"

# ========================================
# FINDER SETTINGS - All still valid
# ========================================

echo "Configuring Finder settings..."

# Show the ~/Library and /Volumes folder - STILL VALID
chflags nohidden ~/Library
sudo chflags nohidden /Volumes

# Avoid creating .DS_Store files on network or USB volumes - STILL VALID
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Automatically open a new Finder window when a volume is mounted - STILL VALID
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Show status bar in Finder - STILL VALID
defaults write com.apple.finder ShowStatusBar -bool true

# Display full POSIX path as Finder window title - STILL VALID
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable the warning when changing a file extension - STILL VALID
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Set the Finder prefs for showing volumes on the Desktop - STILL VALID
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# ========================================
# KEYBOARD SETTINGS - Updated for Sequoia
# ========================================

echo "Configuring keyboard settings..."

# Key repeat settings - STILL VALID but may need additional setting in Sequoia
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 25

# IMPORTANT: For Sequoia, also disable press-and-hold to enable key repeat
# This is required for key repeat to work properly in Sequoia
defaults write -g ApplePressAndHoldEnabled -bool false

echo "⚠️  NOTE: You may need to reboot for key repeat settings to take effect in Sequoia"

# ========================================
# SYSTEM PREFERENCES - Updated paths for Sequoia
# ========================================

echo "Configuring system preferences..."

# Save to disk by default, instead of iCloud - STILL VALID
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Expand print panel by default - STILL VALID
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Automatically quit printer app once the print jobs complete - STILL VALID
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable auto-correct - STILL VALID
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ========================================
# MENU BAR SETTINGS - Updated for Sequoia
# ========================================

echo "Configuring menu bar settings..."

# Set the date format in the menu bar clock - STILL VALID
defaults write com.apple.menuextra.clock "DateFormat" "EEE d MMM h:mm:ss a"

# Set the battery to show percentage - UPDATED for Sequoia
# In Sequoia, this is now handled differently through Control Center
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

# Apply UI settings
killall SystemUIServer

# ========================================
# DOCK SETTINGS - All still valid
# ========================================

echo "Configuring Dock settings..."

# Set the dock preferences size - STILL VALID
defaults write com.apple.dock tilesize -int 60

# Set the dock to autohide with fast animation - STILL VALID
defaults write com.apple.Dock autohide -bool true
defaults write com.apple.Dock autohide-delay -float 0.0001
defaults write com.apple.dock autohide-time-modifier -float 0.25
defaults write com.apple.dock tilesize -float 42.0

# Run the screensaver if we're in the bottom-left hot corner - STILL VALID
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

killall Dock

# ========================================
# POWER MANAGEMENT - All still valid
# ========================================

echo "Configuring power management..."

# Power settings - STILL VALID
# Set display sleep times: 3h on adapter, 10m on battery
sudo pmset sleep 0
sudo pmset -a displaysleep 180
sudo pmset -b displaysleep 10

# ========================================
# SAFARI DEVELOPMENT SETTINGS - Still valid
# ========================================

echo "Configuring Safari for development..."

# Set up Safari for development - STILL VALID
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# ========================================
# NETWORK SETTINGS - Still valid
# ========================================

echo "Configuring network settings..."

# Use AirDrop over every interface - STILL VALID
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# ========================================
# SCREENSHOT SETTINGS - All still valid
# ========================================

echo "Configuring screenshot settings..."

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

# ========================================
# RECTANGLE APP SETTINGS - Still valid if using Rectangle
# ========================================

# NOTE: macOS Sequoia now includes built-in window tiling
# Rectangle may not be necessary for basic window management
# Uncomment the following line if you still want to use Rectangle with Spectacle shortcuts:
# defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true

echo "✅ macOS setup complete!"
echo ""
echo "MANUAL STEPS REQUIRED:"
echo "1. Go to System Settings > Privacy & Security"
echo "2. Under 'Allow applications downloaded from:', select 'Anywhere'"
echo "3. Reboot your system for all changes to take effect"
echo ""
echo "NEW IN SEQUOIA:"
echo "• Built-in window tiling (drag windows to screen edges)"
echo "• New Passwords app (replaces need for many password managers)"
echo "• Enhanced security requiring manual Gatekeeper confirmation"
echo ""
echo "Consider using built-in features before installing third-party alternatives!"
