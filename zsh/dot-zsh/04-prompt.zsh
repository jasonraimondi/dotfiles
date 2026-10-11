if [[ $HOST == dev-box-* ]]; then
  zstyle ':prezto:module:editor:info:keymap:primary' format ' %B%F{magenta}❯%F{blue}❯%F{green}❯%f%b'
  zstyle ':prezto:module:git:info:branch' format ' %%B%F{magenta}%b%f%%b'
  PROMPT=${PROMPT/'%F{4}${_prompt_sorin_pwd}'/'%F{green}${_prompt_sorin_pwd}'}
fi
