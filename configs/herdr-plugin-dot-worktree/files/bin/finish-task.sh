#!/usr/bin/env bash
# dot.worktree — action "finish-task".
# Pick a live task from the `dot task list --json` table, then delegate to
# `dot task finish`, which closes tabs/panes and removes the worktree (§8.5).
set -euo pipefail

DOT="${DOT_BIN:-dot}"
HERDR="${HERDR_BIN_PATH:-herdr}"   # injected by Herdr; dot reads it too
WS="${HERDR_WORKSPACE_ID:-}"       # current workspace (dot resolves it itself)
PANE="${HERDR_PANE_ID:-}"          # calling pane

json="$("$DOT" task list --json)"
task="$(printf '%s' "$json" | jq -r '
  (if type == "array" then . else (.tasks // .data // []) end)[]
  | (.task // .id // .name // empty)' \
  | gum choose --header 'Finish which task?')" || exit 0

[[ -n "$task" ]] || exit 0
exec "$DOT" task finish "$task"
