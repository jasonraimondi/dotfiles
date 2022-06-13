export GPG_TTY=$(tty)
export EDITOR='nvim'
export GIT_EDITOR='nvim'

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
