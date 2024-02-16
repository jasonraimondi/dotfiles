
function asciinema() {
  nix-shell -p asciinema --run "asciinema $*"
}
function dive() {
  nix-shell -p dive --run "dive $*"
}
function heroku() {
  nix-shell -p heroku --run "heroku $*"
}
function masscan() {
  nix-shell -p masscan --run "masscan $*"
}
function overmind() {
  nix-shell -p overmind --run "overmind $*"
}
function restic() {
  nix-shell -p restic --run "restic $*"
}
function yt-dlp() {
  nix-shell -p yt-dlp ffmpeg --run "yt-dlp $*"
}
function ncdu() {
  nix-shell -p ncdu ffmpeg --run "ncdu --color dark -rr -x --exclude .git --exclude node_modules $*"
}
