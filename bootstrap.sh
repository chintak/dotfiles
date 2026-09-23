#!/bin/sh
# bootstrap.sh — the single curl entrypoint for the dotfiles `dot` CLI.
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
#     -- init --profile mac
#
# It downloads `dot`, installs it on PATH, then forwards every argument to
# it. Needs only bash, curl, git, and jq — bash is required by `dot` itself.
#
# Overrides:
#   DOT_REPO_URL  where to fetch `dot` from (default: this repo)
#   DOT_REF       branch, tag, or SHA to pin to (default: master)
#   DOT_BIN_DIR   where to install the CLI (default: ~/.local/bin)
#   DOT_REPO      repo clone location, passed through to `dot`
#   DOT_STORE     versioned store location, passed through to `dot`
#   DOT_STATE     lockfile location, passed through to `dot`
set -eu

REPO_URL="${DOT_REPO_URL:-https://github.com/chintak/dotfiles}"
REF="${DOT_REF:-master}"
BIN_DIR="${DOT_BIN_DIR:-$HOME/.local/bin}"

# Re-export so the values survive `exec dot` below.
export DOT_REPO_URL="$REPO_URL"
export DOT_REF="$REF"
export DOT_BIN_DIR="$BIN_DIR"
if [ -n "${DOT_REPO:-}" ];  then export DOT_REPO;  fi
if [ -n "${DOT_STORE:-}" ]; then export DOT_STORE; fi
if [ -n "${DOT_STATE:-}" ]; then export DOT_STATE; fi

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }

for dep in bash curl git jq; do
  command -v "$dep" >/dev/null 2>&1 || die "missing dependency: $dep"
done

# raw_url <repo-url> <ref> <path> — map a GitHub clone URL to a raw file URL.
# Returns non-zero for anything that isn't a recognizable GitHub repo.
raw_url() {
  url="$1"; ref="$2"; path="$3"; slug=""
  case "$url" in
    https://github.com/*)   slug="${url#https://github.com/}" ;;
    http://github.com/*)    slug="${url#http://github.com/}" ;;
    git@github.com:*)       slug="${url#git@github.com:}" ;;
    ssh://git@github.com/*) slug="${url#ssh://git@github.com/}" ;;
    *) return 1 ;;
  esac
  slug="${slug%.git}"
  case "$slug" in /*) slug="${slug#/}" ;; esac
  printf 'https://raw.githubusercontent.com/%s/%s/%s\n' "$slug" "$ref" "$path"
}

# fetch_dot <dest> — obtain the `dot` script, preferring cheap local sources.
fetch_dot() {
  dest="$1"
  self_dir=""
  case "$0" in
    */*) self_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)" ;;
  esac
  if [ -n "$self_dir" ] && [ -f "$self_dir/dot" ]; then
    log "using local dot: $self_dir/dot"
    cp "$self_dir/dot" "$dest"
    return 0
  fi
  if [ -n "${DOT_REPO:-}" ] && [ -f "${DOT_REPO%/}/dot" ]; then
    log "using dot from DOT_REPO: ${DOT_REPO%/}/dot"
    cp "${DOT_REPO%/}/dot" "$dest"
    return 0
  fi
  if url="$(raw_url "$REPO_URL" "$REF" dot)"; then
    log "downloading dot @ $REF"
    curl -fsSL "$url" -o "$dest"
    return 0
  fi
  log "cloning $REPO_URL @ $REF"
  tmp="$(mktemp -d)"
  if git clone --depth 1 --branch "$REF" "$REPO_URL" "$tmp/repo" >/dev/null 2>&1; then
    cp "$tmp/repo/dot" "$dest"
    rm -rf "$tmp"
  else
    rm -rf "$tmp"
    die "could not fetch dot from $REPO_URL @ $REF"
  fi
}

mkdir -p "$BIN_DIR" || die "cannot create $BIN_DIR"
tmp_dot="$BIN_DIR/.dot.tmp.$$"
trap 'rm -f "$tmp_dot"' EXIT INT TERM

fetch_dot "$tmp_dot"
[ -s "$tmp_dot" ] || die "downloaded dot is empty"
chmod +x "$tmp_dot"
mv "$tmp_dot" "$BIN_DIR/dot"
trap - EXIT INT TERM

case ":$PATH:" in
  *":$BIN_DIR:"*) : ;;
  *) warn "$BIN_DIR is not on PATH — add it to your shell:  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

log "installed dot -> $BIN_DIR/dot"

# Ensure `dot` resolves to the copy we just installed, then hand off.
PATH="$BIN_DIR:$PATH"
export PATH
exec dot "$@"
