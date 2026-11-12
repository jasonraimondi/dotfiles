#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT

mkdir -p "$sandbox/bin" "$sandbox/zsh/dot-zsh" "$sandbox/stub"
cp "$repo/bin/secrets-sync" "$sandbox/bin/secrets-sync"
tpl="$sandbox/zsh/dot-zsh/00-secrets.tpl"
out="$sandbox/zsh/dot-zsh/00-SECRETS.zsh"

cat >"$sandbox/stub/op" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ -z "${STUB_OP_LOCKED:-}" ]] || { echo "[ERROR] 1Password is locked" >&2; exit 1; }
case "$1" in
  read)
    [[ "$2" != *BAD* ]] || { echo "[ERROR] could not resolve $2" >&2; exit 1; }
    echo "value"
    ;;
  inject)
    shift
    while (($#)); do
      case "$1" in
        -f) shift ;;
        -i) in="$2"; shift 2 ;;
        -o) dest="$2"; shift 2 ;;
      esac
    done
    grep -q 'BAD' "$in" && { echo "[ERROR] could not resolve" >&2; exit 1; }
    sed -E 's#op://[^"]*#value#' "$in" >"$dest"
    ;;
esac
STUB
chmod +x "$sandbox/stub/op"

run() { PATH="$sandbox/stub:$PATH" "$sandbox/bin/secrets-sync" "$@"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

printf 'export GOOD_ONE="op://Private/dotfiles/GOOD_ONE"\n' >"$tpl"

echo "case 1: locked op leaves existing output byte-identical"
printf 'export OLD="keep"\n' >"$out"
cp "$out" "$sandbox/before"
if STUB_OP_LOCKED=1 run 2>/dev/null; then fail "locked op exited 0"; fi
cmp -s "$out" "$sandbox/before" || fail "existing output was modified"
leftovers=("$sandbox/zsh/dot-zsh"/*)
((${#leftovers[@]} == 2)) || fail "temp file left behind: ${leftovers[*]}"

echo "case 2: --check names the bad reference and writes nothing"
rm -f "$out"
printf 'export GOOD_ONE="op://Private/dotfiles/GOOD_ONE"\nexport BAD_ONE="op://Private/dotfiles/BAD_ONE"\n' >"$tpl"
if err="$(run --check 2>&1 >/dev/null)"; then fail "--check exited 0 with a bad reference"; fi
grep -q 'op://Private/dotfiles/BAD_ONE' <<<"$err" || fail "stderr does not name the bad reference: $err"
[[ ! -e "$out" ]] || fail "--check wrote the output file"

echo "case 3: happy path writes the file with mode 600"
printf 'export GOOD_ONE="op://Private/dotfiles/GOOD_ONE"\n' >"$tpl"
run
[[ -s "$out" ]] || fail "output missing or empty"
mode="$(stat -f %Lp "$out" 2>/dev/null || stat -c %a "$out")"
[[ "$mode" == 600 ]] || fail "mode is $mode, want 600"

echo "case 4: missing template fails loudly"
rm -f "$tpl"
if run --check 2>/dev/null; then fail "--check exited 0 with no template"; fi

echo "PASS"
