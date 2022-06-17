# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
export GPG_TTY=$(tty);

export EDITOR='nvim'
export GIT_EDITOR='nvim'
export GUI_EDITOR='subl'

# homebrew stop analytics
export HOMEBREW_NO_ANALYTICS=1
# export HOMEBREW_NO_ENV_HINTS=1

# blocks post install messages from some node_modules
export ADBLOCK=true
export NEXT_TELEMETRY_DISABLED=1

# docker
export COMPOSE_DOCKER_CLI_BUILD=1
export DOCKER_BUILDKIT=1

# display how long all tasks over 10 seconds take
export REPORTTIME=10


# Enable persistent REPL history for `node`.
export NODE_REPL_HISTORY=~/.node_history;
# Allow 32³ entries; the default is 1000.
export NODE_REPL_HISTORY_SIZE='32768';
# Use sloppy mode by default, matching web browsers.
export NODE_REPL_MODE='sloppy';

# Don’t clear the screen after quitting a manual page.
export MANPAGER='less -X';