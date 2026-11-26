#!/usr/bin/env bash
#
# Builds the Home Manager generation described by flake.nix and activates it,
# which links this checkout's dotfiles and agent skills into $HOME.
#
# Usage: setup-home.sh [-p|--profile PROFILE] [-n|--dry-run] [-D|--delete] [-b|--backup] [-h|--help]

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: setup-home.sh [-p|--profile PROFILE] [-n|--dry-run] [-D|--delete] [-b|--backup] [-h|--help]

  (no args)        link the dotfiles and agent skills into $HOME
  -p, --profile    default or desktop for a workstation, server for a headless machine
  -n, --dry-run    build the generation and print what activating it would do
  -D, --delete     remove every link an earlier run created
  -b, --backup     move a file in the way of a link to FILE.hm-backup instead of stopping
  -h, --help       show this message
EOF
}

profile=default
delete=
while (( $# > 0 )); do
  case "$1" in
    -p|--profile)
      (( $# > 1 )) || { echo "$1 needs a profile" >&2; usage >&2; exit 2; }
      profile=$2
      shift
      ;;
    -D|--delete)  delete=1 ;;
    -n|--dry-run) export DRY_RUN=1 ;;
    -b|--backup)  export HOME_MANAGER_BACKUP_EXT=hm-backup ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$profile" in
  default|desktop|server) ;;
  *) echo "unknown profile: $profile" >&2; usage >&2; exit 2 ;;
esac

configuration=$profile
# -D keeps the profile's packages installed, so a server does not gain the
# desktop packages by unlinking.
if [[ -n "$delete" ]]; then
  configuration=unlinked
  [[ "$profile" != server ]] || configuration=server-unlinked
fi

# A non-interactive shell does not source the profile script that puts nix on PATH.
export PATH="$PATH:/nix/var/nix/profiles/default/bin"

generation="$(
  DOTFILES_HOME="$REPO" nix --extra-experimental-features 'nix-command flakes' \
    build --impure --no-link --print-out-paths \
    "$REPO#homeConfigurations.$configuration.activationPackage"
)"

exec "$generation/activate"
