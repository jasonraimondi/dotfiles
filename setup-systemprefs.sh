#!/usr/bin/env bash

set -euo pipefail

# macOS Setup Script - Validated for macOS 26.2 (25C56)
# Last updated: February 2026
# Tested on: macOS 26.2 (25C56)

DRY_RUN=false

case "${1:-}" in
  --dry-run|-n)
    DRY_RUN=true
    shift
    ;;
  --help|-h)
    echo "Usage: $0 [--dry-run|-n]"
    exit 0
    ;;
esac

if [[ $# -gt 0 ]]; then
  echo "Unknown argument(s): $*"
  echo "Usage: $0 [--dry-run|-n]"
  exit 1
fi

print_cmd() {
  printf '[dry-run] '
  printf '%q ' "$@"
  printf '\n'
}

run() {
  if [[ "$DRY_RUN" == true ]]; then
    print_cmd "$@"
    return 0
  fi
  "$@"
}

run_quiet() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '2>/dev/null\n'
    return 0
  fi
  "$@" 2>/dev/null
}

if [[ "$DRY_RUN" == true ]]; then
  echo "Starting macOS setup script for macOS 26.x (dry-run mode; no changes will be made)..."
else
  echo "Starting macOS setup script for macOS 26.x..."
fi

# ========================================
# SECURITY SETTINGS
# ========================================

echo "Configuring Gatekeeper..."
# On macOS 26.x this requires confirmation in System Settings
# --global-disable is the current flag; keep --master-disable fallback for older releases
if [[ "$DRY_RUN" == true ]]; then
  run sudo spctl --global-disable
  run sudo spctl --master-disable
  echo "⚠️  Gatekeeper global disable requires manual confirmation in System Settings > Privacy & Security"
  echo "   If prompted, allow 'Anywhere' in 'Allow applications downloaded from:'"
else
  if ! run sudo spctl --global-disable; then
    run sudo spctl --master-disable || true
    echo "⚠️  Gatekeeper global disable requires manual confirmation in System Settings > Privacy & Security"
    echo "   If prompted, allow 'Anywhere' in 'Allow applications downloaded from:'"
  fi
fi

# ========================================
# FINDER SETTINGS
# ========================================

echo "Configuring Finder settings..."

# Show the ~/Library and /Volumes folder
run chflags nohidden ~/Library
run sudo chflags nohidden /Volumes

# Avoid creating .DS_Store files on network or USB volumes
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Automatically open a new Finder window when removable media is mounted
# (legacy key, still writable on macOS 26.2)
run defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
run defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
run defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

# Finder UI preferences
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
run defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
run defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
run defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# ========================================
# KEYBOARD SETTINGS
# ========================================

echo "Configuring keyboard settings..."

# Fast key repeat + disable press-and-hold so repeat works consistently
run defaults write -g KeyRepeat -int 2
run defaults write -g InitialKeyRepeat -int 25
run defaults write -g ApplePressAndHoldEnabled -bool false

echo "⚠️  NOTE: You may need to log out/restart for key repeat settings to fully apply"

# ========================================
# SYSTEM PREFERENCES
# ========================================

echo "Configuring system preferences..."

# Save to disk by default, instead of iCloud
run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Expand print panel by default
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Automatically quit printer app once print jobs complete
run defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable auto-correct
run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ========================================
# MENU BAR / CONTROL CENTER SETTINGS
# ========================================

echo "Configuring menu bar settings..."

# Clock settings (DateFormat is unreliable on macOS 26.x; use supported keys)
run defaults write com.apple.menuextra.clock ShowAMPM -bool true
run defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
run defaults write com.apple.menuextra.clock ShowSeconds -bool true
run defaults write com.apple.menuextra.clock ShowDate -int 1

# Battery percentage (host-specific Control Center preference)
run defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true

run killall SystemUIServer

# ========================================
# DOCK SETTINGS
# ========================================

echo "Configuring Dock settings..."

run defaults write com.apple.dock autohide -bool true
run defaults write com.apple.dock autohide-delay -float 0.0001
run defaults write com.apple.dock autohide-time-modifier -float 0.25
run defaults write com.apple.dock tilesize -float 42.0

# Run screensaver from bottom-left hot corner
run defaults write com.apple.dock wvous-bl-corner -int 5
run defaults write com.apple.dock wvous-bl-modifier -int 0

run killall Dock

# ========================================
# POWER MANAGEMENT
# ========================================

echo "Configuring power management..."

# Never system sleep, with display sleep tuned for AC/Battery
run sudo pmset -a sleep 0
run sudo pmset -a displaysleep 180
run sudo pmset -b displaysleep 10

# ========================================
# SAFARI DEVELOPMENT SETTINGS
# ========================================

echo "Configuring Safari for development..."

# Works for WebKit-based developer context menus in many apps
run defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Safari 26.x key name (old keys removed)
if [[ "$DRY_RUN" == true ]]; then
  run defaults write com.apple.Safari IncludeDevelopMenuPreferenceKey -bool true
  echo "⚠️  Safari CLI write can fail due to sandbox/privacy restrictions."
  echo "   Manually enable if needed: Safari > Settings > Advanced > Show features for web developers"
else
  if ! run_quiet defaults write com.apple.Safari IncludeDevelopMenuPreferenceKey -bool true; then
    echo "⚠️  Could not set Safari Develop menu via CLI (sandbox/privacy restriction)."
    echo "   Manually enable: Safari > Settings > Advanced > Show features for web developers"
  fi
fi

# ========================================
# NETWORK SETTINGS
# ========================================

echo "Configuring network settings..."

# Use AirDrop over every interface
run defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# ========================================
# SCREENSHOT SETTINGS
# ========================================

echo "Configuring screenshot settings..."

run mkdir -p ~/Pictures/screenshots
run defaults write com.apple.screencapture location ~/Pictures/screenshots
run defaults write com.apple.screencapture name ""
run defaults write com.apple.screencapture type png
run defaults write com.apple.screencapture disable-shadow -bool true

run killall SystemUIServer

# ========================================
# RECTANGLE APP SETTINGS (OPTIONAL)
# ========================================

# macOS 26.x has strong built-in window tiling. Uncomment if you still use Rectangle:
# defaults write com.knollsoft.Rectangle alternateDefaultShortcuts -bool true

if [[ "$DRY_RUN" == true ]]; then
  echo "✅ Dry run complete. No changes were made."
else
  echo "✅ macOS setup complete!"
fi

echo ""
echo "MANUAL STEPS MAY STILL BE REQUIRED:"
echo "1. System Settings > Privacy & Security > confirm Gatekeeper 'Anywhere' if desired"
echo "2. Safari > Settings > Advanced > Show features for web developers (if CLI write failed)"
echo "3. Reboot or log out/in for all settings to settle"
