#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: add-skill.sh [add] <repo-url> --skill <name> [--ref <ref>] [--path <subpath>] [--dest <dir>]

Download a single skill folder from a git repo into ./vendor/<name>/.
No lockfile, no prompts.

Arguments:
  <repo-url>        Git URL (https or ssh) of the source repo
  --skill <name>    Skill folder to extract
  --ref <ref>       Branch or tag (default: repo's default branch)
  --path <subpath>  Path within the repo (default: skills/<name>)
  --dest <dir>      Destination dir (default: ./vendor)
  -f, --force       Overwrite existing destination without confirmation

Example:
  ./add-skill.sh add https://github.com/anthropics/skills --skill frontend-design
EOF
}

REPO=""
SKILL=""
REF=""
SUBPATH=""
DEST="./vendor"
FORCE=0

# Allow `add-skill.sh add <repo> ...` to mirror `skills add <repo> ...`
if [ "${1:-}" = "add" ]; then
  shift
fi

while [ $# -gt 0 ]; do
  case "$1" in
    --skill) SKILL="${2:-}"; shift 2 ;;
    --ref) REF="${2:-}"; shift 2 ;;
    --path) SUBPATH="${2:-}"; shift 2 ;;
    --dest) DEST="${2:-}"; shift 2 ;;
    -f|--force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown flag: $1" >&2; usage; exit 1 ;;
    *)
      if [ -z "$REPO" ]; then
        REPO="$1"
      else
        echo "Unexpected argument: $1" >&2
        usage
        exit 1
      fi
      shift ;;
  esac
done

if [ -z "$REPO" ]; then
  echo "Error: repo URL is required" >&2
  usage
  exit 1
fi
if [ -z "$SKILL" ]; then
  echo "Error: --skill is required" >&2
  usage
  exit 1
fi

SUBPATH="${SUBPATH:-skills/$SKILL}"

TMP="$(mktemp -d -t skill-fetch.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Fetching $SKILL from $REPO (path: $SUBPATH${REF:+, ref: $REF})"

# Shallow + sparse so we only download the one folder.
git clone \
  --depth 1 \
  --filter=blob:none \
  --sparse \
  ${REF:+--branch "$REF"} \
  "$REPO" "$TMP/repo" >/dev/null 2>&1

git -C "$TMP/repo" sparse-checkout set --no-cone "$SUBPATH" >/dev/null

SRC="$TMP/repo/$SUBPATH"
if [ ! -d "$SRC" ]; then
  echo "Error: '$SUBPATH' not found in $REPO" >&2
  exit 1
fi

mkdir -p "$DEST"
TARGET="$DEST/$SKILL"

if [ -e "$TARGET" ]; then
  if [ "$FORCE" -ne 1 ]; then
    printf "%s exists. Overwrite? [y/N] " "$TARGET"
    read -r reply
    case "$reply" in
      y|Y|yes|YES) ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  fi
  rm -rf "$TARGET"
fi

cp -R "$SRC" "$TARGET"
echo "✓ Installed $SKILL → $TARGET"
