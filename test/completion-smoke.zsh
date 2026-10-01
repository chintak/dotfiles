#!/usr/bin/env zsh
# completion-smoke.zsh — smoke test for completions/_dot (the `dot` zsh
# completion). Runs under macOS stock zsh. Exit 0 only when every
# assertion passes; every failure is printed with its label.
#
# Two layers (the plan's Risks section allows the zpty layer to be lean):
#
#   0. load test (pinned): in `zsh -f`, put the completions dir on fpath,
#      run compinit, then source _dot; assert _dot is defined and compdef
#      registration came from compinit scanning fpath — not from bare
#      sourcing. (fpath must precede compinit for registration to happen
#      at all; the point of the recipe is that compinit does the
#      registering, which is why the assert checks _comps[dot].)
#   1. unit: source _dot directly and call the dynamic candidate helpers
#      against a sandbox fixture — deterministic, no pty.
#   2. zpty: drive real interactive tab completion in a pty child and
#      assert what the completion system actually offers.
#
# Fixture (mktemp sandbox, env-injected into the child):
#   DOT_REPO   = fixture  (configs/helix, configs/herdr; profiles/dev.conf,
#                          profiles/prod.conf)
#   DOT_STATE  = fixture/state  (lockfile: helix installed)
#   DOT_STORE  = fixture/store  (helix/0.0.9 + helix/0.1.0)
# so `dot list --json` reports helix installed, herdr not-installed.

emulate -L zsh

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
COMPL_DIR="$ROOT/completions"

integer fails=0
ok()    { print "ok   $1"; }
bad()   { print -u2 "FAIL $1"; fails=$((fails + 1)); }
have()  { [[ "$3" == *"$2"* ]] && ok "$1" || bad "$1 — missing [$2]"; }
havent(){ [[ "$3" != *"$2"* ]] && ok "$1" || bad "$1 — unwanted [$2]"; }

# ── fixture ───────────────────────────────────────────────────────────
FIX="$(mktemp -d "${TMPDIR:-/tmp}/dot-completion-smoke.XXXXXX")"
mkdir -p "$FIX/bin" "$FIX/bin-stub" "$FIX/zd" "$FIX/state" \
         "$FIX/store/helix/0.0.9" "$FIX/store/helix/0.1.0" \
         "$FIX/configs/helix" "$FIX/configs/herdr" "$FIX/profiles" \
         "$FIX/targets"

mkdir -p "$FIX/configs/helix" "$FIX/configs/herdr" "$FIX/profiles" "$FIX/targets"

for c in helix herdr; do
  cat > "$FIX/configs/$c/manifest" <<EOF
version     = 0.1.0
description = $c fixture config
file        = x|$FIX/targets/$c
EOF
done
echo x > "$FIX/store/helix/0.1.0/x"
echo x > "$FIX/store/helix/0.0.9/x"

cat > "$FIX/state/installed.json" <<EOF
{"lockfileVersion":1,"configs":{"helix":{"version":"0.1.0","mode":"symlink",
"hash":"x","store":"$FIX/store/helix/0.1.0","targets":["$FIX/targets/helix"],
"postApplyOk":true,"installedAt":"2026-01-01T00:00:00Z"}}}
EOF

printf '# dev profile\nhelix\nherdr\n' > "$FIX/profiles/dev.conf"
printf '# prod profile\nhelix\n'      > "$FIX/profiles/prod.conf"

# wrapper: the real dot script from this checkout, fixture-driven via env
cat > "$FIX/bin/dot" <<EOF
#!/bin/sh
exec "$ROOT/dot" "\$@"
EOF
chmod +x "$FIX/bin/dot"

# stub: an "old" dot that silently ignores flags (no --json anywhere),
# like cmd_profiles/cmd_list before this change — pretty output only
cat > "$FIX/bin-stub/dot" <<'EOF'
#!/bin/sh
case "$1" in
  profiles)
    printf '\033[1;34mdev\033[0m\n  helix\n  herdr\n'
    printf '\033[1;34mprod\033[0m\n  helix\n' ;;
  list)
    printf 'helix      0.1.0  ok\nherdr      0.2.0  not-installed\n' ;;
esac
exit 0
EOF
chmod +x "$FIX/bin-stub/dot"

# pty child zshrc: minimal — fpath BEFORE compinit (the hook ordering the
# zshrc config relies on), no menu, no matcher fuzz, no pagination.
cat > "$FIX/zd/.zshrc" <<EOF
M=ZDONE
bindkey -e
autoload -Uz compinit
fpath=("$COMPL_DIR" \$fpath)
compinit -i
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list ''
LISTMAX=9999
PS1='ZOK> '
EOF

# ── 0. pinned load test ───────────────────────────────────────────────
lt="$(env COMPL="$COMPL_DIR" zsh -f -c '
  fpath=("$COMPL" $fpath)
  autoload -Uz compinit && compinit
  source "$COMPL/_dot"
  print "funcs=${+functions[_dot]}"
  print "comp=${_comps[dot]:-MISSING}"
' 2>/dev/null)"
[[ "$lt" == *"funcs=1"* ]]    && ok "load: _dot defined after source" \
                              || bad "load: _dot not defined ($lt)"
[[ "$lt" == *"comp=_dot"* ]]  && ok "load: compdef registered via compinit+fpath" \
                              || bad "load: compdef not registered ($lt)"

# ── 1. unit: helpers against the fixture ──────────────────────────────
unit() { # unit <label> <bin-dir> <zsh-code> <expected>
  local got
  got="$(env COMPL="$COMPL_DIR" FIX="$FIX" PATH="$2:$PATH" \
    DOT_REPO="$FIX" DOT_STATE="$FIX/state" DOT_STORE="$FIX/store" \
    zsh -f -c "$3" 2>/dev/null)"
  [[ "$got" == "$4" ]] && ok "$1" || bad "$1 — got [$got] want [$4]"
}
JSON_BIN="$FIX/bin"
STUB_BIN="$FIX/bin-stub"

unit "configs all (helix+herdr)"      "$JSON_BIN" 'source "$COMPL/_dot"; _dot_configs all'       $'helix\nherdr'
unit "configs installed (helix only)" "$JSON_BIN" 'source "$COMPL/_dot"; _dot_configs installed' "helix"
unit "profiles via --json"            "$JSON_BIN" 'source "$COMPL/_dot"; _dot_profiles'          $'dev\nprod'
unit "rollback store versions"        "$JSON_BIN" 'source "$COMPL/_dot"; _dot_rollback_versions helix' $'0.0.9\n0.1.0'
# fallback path: stub dot has no --json → pretty (ANSI) parse for profiles,
# empty-but-no-crash for configs
unit "stub profiles → pretty fallback" "$STUB_BIN" 'source "$COMPL/_dot"; _dot_profiles'  $'dev\nprod'
unit "stub configs → empty, no crash"  "$STUB_BIN" 'source "$COMPL/_dot"; _dot_configs all' ""

# ── 2. zpty: real tab completion ──────────────────────────────────────
# One fresh interactive session per assertion group: cycling TABs through a
# single shared session proved nondeterministic under zpty (input landing
# outside zle's control), while the first TAB of a fresh session is stable.
zpty_tab() { # zpty_tab <bin-dir> <cmdline> — drive one TAB; sets $OUT
  local bindir="$1" cmdline="$2" DRAIN chunk
  OUT=""
  zmodload zsh/zpty 2>/dev/null || { print -u2 "FAIL zpty module unavailable"; return 1; }

  zpty -b smoke env PATH="$bindir:$PATH" ZDOTDIR="$FIX/zd" \
    DOT_REPO="$FIX" DOT_STATE="$FIX/state" DOT_STORE="$FIX/store" \
    zsh -d -i 2>/dev/null || { print -u2 "FAIL zpty spawn"; return 1; }

  # Non-pattern zpty -r reads are non-blocking and empty when no data is
  # pending — poll with sleeps so nothing here can hang.
  drain_until() { # drain_until <needle> — accumulate child output into DRAIN
    local needle="$1"
    DRAIN=""
    local -i quiet=0
    while (( quiet < 12 )); do
      chunk=""
      zpty -r smoke chunk
      if [[ -n "$chunk" ]]; then
        DRAIN+="$chunk"; quiet=0
        [[ "$DRAIN" == *"$needle"* ]] && return 0
      else
        quiet=$((quiet + 1)); sleep 0.05
      fi
    done
    return 1
  }

  drain_until 'ZOK>' || { print -u2 "FAIL child prompt never appeared"; zpty -d smoke 2>/dev/null; return 1; }

  # hit TAB on the typed line, kill it, then print a marker via $M (the
  # needle never appears in the pending zle line, so a match can only come
  # from executed output, not from zle's own drawing)
  zpty -w -n smoke "$cmdline"
  zpty -w -n smoke $'\t'
  zpty -w -n smoke $'\x15'
  zpty -w smoke 'print -r -- "$M"'$'\n'
  if ! drain_until 'ZDONE'; then
    print -u2 "FAIL completion never settled (no marker)"
    zpty -d smoke 2>/dev/null
    return 1
  fi
  OUT="$DRAIN"
  zpty -d smoke 2>/dev/null
  return 0
}

zpty_tab "$FIX/bin" "dot " && {
  have  "dot <TAB>: purge"         "purge"     "$OUT"
  have  "dot <TAB>: review"         "review"     "$OUT"
  have  "dot <TAB>: web"            "web"        "$OUT"
  have  "dot <TAB>: ls"             "ls"         "$OUT"
  have  "dot <TAB>: task"           "task"       "$OUT"
  have  "dot <TAB>: help"           "help"       "$OUT"
}
zpty_tab "$FIX/bin" "dot apply " && {
  have   "apply TAB → helix"        "helix" "$OUT"
  have   "apply TAB → herdr"        "herdr" "$OUT"
  havent "apply TAB excludes prod"  "prod"  "$OUT"
}
zpty_tab "$FIX/bin" "dot apply he" && {
  have "apply he<TAB> → helix"      "helix" "$OUT"
  have "apply he<TAB> → herdr"      "herdr" "$OUT"
}
zpty_tab "$FIX/bin" "dot apply --profile " && {
  have "apply --profile → dev"      "dev"  "$OUT"
  have "apply --profile → prod"     "prod" "$OUT"
}
zpty_tab "$FIX/bin" "dot forget " && {
  have   "forget TAB → installed helix"  "helix" "$OUT"
  havent "forget TAB excludes herdr"     "herdr" "$OUT"
}
zpty_tab "$FIX/bin" "dot info " && {
  have "info TAB → helix"           "helix" "$OUT"
  have "info TAB → herdr"           "herdr" "$OUT"
}
zpty_tab "$FIX/bin" "dot bump " && {
  have "bump TAB → helix"           "helix" "$OUT"
  have "bump TAB → herdr"           "herdr" "$OUT"
}
zpty_tab "$FIX/bin" "dot bump helix " && {
  have "bump level → major"         "major" "$OUT"
  have "bump level → minor"         "minor" "$OUT"
  have "bump level → patch"         "patch" "$OUT"
}
zpty_tab "$FIX/bin" "dot name " && {
  have  "name TAB → revert"         "revert" "$OUT"
  have  "name TAB → chore"          "chore"  "$OUT"
  have  "name TAB → feat"           "feat"   "$OUT"
}
zpty_tab "$FIX/bin" "dot apply --" && {
  have   "apply -- → --dry-run"     "--dry-run"   "$OUT"
  have   "apply -- → --force-post"  "--force-post" "$OUT"
  have   "apply -- → --profile"     "--profile"   "$OUT"
  havent "apply -- excludes --no-pull"    "--no-pull"    "$OUT"
  havent "apply -- excludes --ephemeral"  "--ephemeral"  "$OUT"
}
# fallback path through a real pty too: stub dot (no --json) — profiles
# must come from the pretty-parse fallback; configs degrade to nothing
zpty_tab "$FIX/bin-stub" "dot apply --profile " && {
  have "stub: apply --profile → dev"  "dev"  "$OUT"
  have "stub: apply --profile → prod" "prod" "$OUT"
}
zpty_tab "$FIX/bin-stub" "dot apply " && {
  havent "stub: apply TAB yields no configs (no crash)"  "helix" "$OUT"
}

rm -rf "$FIX"

if (( fails )); then
  print -u2 "completion-smoke: $fails failure(s)"
  exit 1
fi
print "completion-smoke: all assertions passed"
