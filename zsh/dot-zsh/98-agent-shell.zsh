# Agents run commands unattended and write bash idioms: a confirmation prompt
# hangs them, a refused overwrite leaves them reading a stale file, and an
# unmatched glob like `grep --include=*.ts` aborts the whole command.
if [[ -n $AI_AGENT || -n $CLAUDECODE ]]; then
  unalias rm cp mv 2>/dev/null
  setopt clobber no_nomatch no_correct
fi
