# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
export GPG_TTY=$TTY

export EDITOR='vim'
export GIT_EDITOR='vim'
export GUI_EDITOR='subl'

# homebrew stop analytics
export HOMEBREW_NO_ANALYTICS=1
# Hide homebrew hints (see `man brew`).
export HOMEBREW_NO_ENV_HINTS=1

export ADBLOCK=true

# disable telemetry
export BETTER_AUTH_TELEMETRY=0

# overmind
export OVERMIND_NO_PORT=1

# display how long all tasks over 10 seconds take
export REPORTTIME=10

# Enable persistent REPL history for `node`.
export NODE_REPL_HISTORY=~/.local/node/history;
# Allow 32³ entries; the default is 1000.
export NODE_REPL_HISTORY_SIZE='32768';
# Use sloppy mode by default, matching web browsers.
export NODE_REPL_MODE='sloppy';

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X';
