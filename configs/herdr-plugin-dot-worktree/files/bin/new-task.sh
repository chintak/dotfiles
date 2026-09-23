#!/usr/bin/env bash
# dot.worktree — action "new-task".
# Prompt for <type> <words…> with gum, then delegate to `dot task new`,
# which owns branch + worktree + agent tab + review pane + web pane (§8.4).
set -euo pipefail

DOT="${DOT_BIN:-dot}"
HERDR="${HERDR_BIN_PATH:-herdr}"   # injected by Herdr; dot reads it too
WS="${HERDR_WORKSPACE_ID:-}"       # current workspace (dot resolves it itself)
PANE="${HERDR_PANE_ID:-}"          # calling pane

if (($#)); then
  argv=("$@")
else
  input="$(gum input \
    --header 'New task — <type> <words…>' \
    --placeholder 'feat add oauth login' \
    --prompt '> ')" || exit 0
  read -r -a argv <<<"$input"
fi

if ((${#argv[@]} < 2)); then
  gum style --foreground 1 'usage: <type> <word>…' >&2
  exit 1
fi

exec "$DOT" task new "${argv[@]}"
