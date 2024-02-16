# Trash / RM
alias rm="trash"

# Clipboard
alias pbtext="pbpaste | textutil -convert txt -stdin -stdout -encoding 30 | pbcopy"
alias pbspaces="pbpaste | expand | pbcopy"

alias dnsflush="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

# Homebrew
alias cask="brew cask"

# Exclude macOS specific files in ZIP archives
alias zip="zip -x *.DS_Store -x *__MACOSX* -x *.AppleDouble*"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Copy pwd to clipboard
alias cpwd="pwd | tr -d '\n' | pbcopy"

# Reload native apps
alias killfinder="killall Finder"
alias killdock="killall Dock"
alias killmenubar="killall SystemUIServer NotificationCenter"
alias killos="killfinder && killdock && killmenubar"

# Empty trash on mounted volumes and main HDD, and clear system logs
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Show system information
alias displays="system_profiler SPDisplaysDataType"
alias cpu="sysctl -n machdep.cpu.brand_string"
alias ram="top -l 1 -s 0 | grep PhysMem"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"
