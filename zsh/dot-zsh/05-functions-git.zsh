function squashit () {
  git reset --soft HEAD~$1 &&
  git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
}

function git-cleanup () {
  echo "\nTHIS CREATES A LIST OF BRANCHES TO DELETE"
  echo "remove ones you'd like to keep from the list"
  echo "waiting 8s..."
  sleep 8
  git branch --merged >/tmp/merged-branches && vim /tmp/merged-branches && xargs git branch -d </tmp/merged-branches
}
