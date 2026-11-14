#!/usr/bin/env bash
#
# Builds the Home Manager generation described by flake.nix and activates it,
# which links this checkout's dotfiles and agent skills into $HOME.
#
# Usage: setup-home.sh [-n|--dry-run] [-D|--delete] [-b|--backup] [-h|--help]

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: setup-home.sh [-n|--dry-run] [-D|--delete] [-b|--backup] [-h|--help]

  (no args)        link the dotfiles and agent skills into $HOME
  -n, --dry-run    build the generation and print what activating it would do
  -D, --delete     remove every link an earlier run created
  -b, --backup     move a file in the way of a link to FILE.hm-backup instead of stopping
  -h, --help       show this message
EOF
}

configuration=default
for arg in "$@"; do
  case "$arg" in
    -D|--delete)  configuration=unlinked ;;
    -n|--dry-run) export DRY_RUN=1 ;;
    -b|--backup)  export HOME_MANAGER_BACKUP_EXT=hm-backup ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

# A non-interactive shell does not source the profile script that puts nix on PATH.
export PATH="$PATH:/nix/var/nix/profiles/default/bin"

generation="$(
  DOTFILES_HOME="$REPO" nix --extra-experimental-features 'nix-command flakes' \
    build --impure --no-link --print-out-paths \
    "$REPO#homeConfigurations.$configuration.activationPackage"
)"

exec "$generation/activate"
