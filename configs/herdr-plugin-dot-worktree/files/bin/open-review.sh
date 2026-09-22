#!/usr/bin/env bash
# dot.worktree — action "open-review".
# Choose a task, focus the workspace's review tab, step into the review
# column, then render that task's diff via `dot review` (§3.2, §8.1).
set -euo pipefail

DOT="${DOT_BIN:-dot}"
HERDR="${HERDR_BIN_PATH:-herdr}"
WS="${HERDR_WORKSPACE_ID:-}"
PANE="${HERDR_PANE_ID:-}"          # calling pane

json="$("$DOT" task list --json)"
task="$(printf '%s' "$json" | jq -r '
  (if type == "array" then . else (.tasks // .data // []) end)[]
  | (.task // .id // .name // empty)' \
  | gum choose --header 'Review which task?')" || exit 0

[[ -n "$task" ]] || exit 0

# Focus the review tab when this workspace has one, then step down into the
# review pane column. Both are best-effort: absence is not an error.
if [[ -n "$WS" ]]; then
  review_tab="$("$HERDR" tab list --workspace "$WS" \
    | jq -r '.result.tabs[]? | select(.label == "review") | .tab_id' | head -n1)"
  if [[ -n "$review_tab" ]]; then
    "$HERDR" tab focus "$review_tab" >/dev/null 2>&1 || true
    "$HERDR" pane focus --direction down >/dev/null 2>&1 || true
  fi
fi

exec "$DOT" review "$task"
