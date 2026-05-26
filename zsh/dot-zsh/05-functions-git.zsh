function squashit () {
  git reset --soft HEAD~$1 &&
  git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
}

function gwr() {
    git worktree remove "$@" &
    echo "PID: $!"
}
