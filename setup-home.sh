#!/usr/bin/env bash
#
# Builds the Home Manager generation described by flake.nix and activates it,
# which links this checkout's dotfiles and agent skills into $HOME.
#
# Usage: setup-home.sh [-p|--profile PROFILE] [-s|--skills] [-n|--dry-run] [-D|--delete] [-b|--backup] [-h|--help]

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: setup-home.sh [-p|--profile PROFILE] [-s|--skills] [-n|--dry-run] [-D|--delete] [-b|--backup] [-h|--help]

  (no args)        link the dotfiles and agent skills into $HOME
  -p, --profile    default or desktop for a workstation, server for a headless machine
  -s, --skills     relink only the agent skills, skipping the rest of activation
  -n, --dry-run    build the generation and print what activating it would do
  -D, --delete     remove every link an earlier run created
  -b, --backup     move a file in the way of a link to FILE.hm-backup instead of stopping
  -h, --help       show this message
EOF
}

profile=default
delete=
skills_only=
while (( $# > 0 )); do
  case "$1" in
    -p|--profile)
      (( $# > 1 )) || { echo "$1 needs a profile" >&2; usage >&2; exit 2; }
      profile=$2
      shift
      ;;
    -s|--skills)  skills_only=1 ;;
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

if [[ -n "$skills_only" && ( -n "$delete" || -n "${DRY_RUN:-}" || -n "${HOME_MANAGER_BACKUP_EXT:-}" ) ]]; then
  echo "-s combines only with -p" >&2
  exit 2
fi

configuration=$profile
# -D keeps the profile's packages installed, so a server does not gain the
# desktop packages by unlinking.
if [[ -n "$delete" ]]; then
  configuration=unlinked
  [[ "$profile" != server ]] || configuration=server-unlinked
fi

# A non-interactive shell does not source the profile script that puts nix on PATH.
export PATH="$PATH:/nix/var/nix/profiles/default/bin"

# The skill links point into this build rather than the active generation, so
# -s roots it to keep garbage collection from leaving them dangling.
state="${XDG_STATE_HOME:-$HOME/.local/state}/home-manager/gcroots"
out_link=(--no-link)
if [[ -n "$skills_only" ]]; then
  mkdir -p "$state"
  out_link=(--out-link "$state/skills-only")
fi

generation="$(
  DOTFILES_HOME="$REPO" nix --extra-experimental-features 'nix-command flakes' \
    build --impure "${out_link[@]}" --print-out-paths \
    "$REPO#homeConfigurations.$configuration.activationPackage"
)"

[[ -n "$skills_only" ]] || exec "$generation/activate"

# Home Manager treats a link into any *-home-manager-files store path as its
# own, so the next full run replaces these links instead of stopping on them.
owned='/nix/store/*-home-manager-files/*'
files="$(realpath "$generation/home-files")"
shopt -s nullglob
for dir in .claude/skills .agents/skills; do
  mkdir -p "$HOME/$dir"
  for link in "$HOME/$dir"/*; do
    [[ -L "$link" && "$(readlink "$link")" == $owned ]] || continue
    [[ -e "$files/$dir/${link##*/}" ]] || { rm "$link"; echo "unlinked $dir/${link##*/}"; }
  done
  for skill in "$files/$dir"/*; do
    link="$HOME/$dir/${skill##*/}"
    if [[ -e "$link" || -L "$link" ]] && [[ "$(readlink "$link")" != $owned ]]; then
      echo "$link is in the way; move it aside and re-run" >&2
      exit 1
    fi
    [[ -L "$link" ]] || echo "linked $dir/${skill##*/}"
    ln -sfn "$skill" "$link"
  done
done
