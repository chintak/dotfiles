#!/usr/bin/env bash
# herdr-subagents — spawn a subagent in its own worktree + NEW TAB.
#
#   spawn.sh <type> <word>… [--prompt TEXT]
#
# Wraps `dot task new <type> <word>… --kind pi --no-focus`. dot creates the
# branch, worktree, agent tab, review pane and web pane; `dot name` guarantees
# the tab, branch and agent name all match. Prints the task id and agent tab id.
#
# Rule (see SKILL.md): a subagent gets a NEW TAB, never a pane split.
set -euo pipefail

if [ "${HERDR_ENV:-}" != 1 ]; then
  echo "spawn.sh: requires HERDR_ENV=1 (run inside Herdr)" >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "usage: spawn.sh <type> <word>… [--prompt TEXT]" >&2
  exit 2
fi

# The task id is `<type>-<words…>`; positional args precede any --flag.
name_args=()
for arg in "$@"; do
  case "$arg" in
    -*) break ;;
    *) name_args+=("$arg") ;;
  esac
done
task=$(dot name "${name_args[@]}")

# Create branch + worktree + NEW TAB (never --focus: the lead keeps focus).
dot task new "$@" --kind pi --no-focus

# Read the tab id from dot's state; never predict IDs.
state="${XDG_STATE_HOME:-$HOME/.local/state}/dot/dev/state.json"
tab=""
if [ -f "$state" ]; then
  tab=$(jq -r --arg t "$task" \
    '[.. | objects | select((.task? // .branch?) == $t) | .tab?]
     | map(select(. != null)) | first // empty' "$state" 2>/dev/null || true)
fi

echo "task: $task"
[ -n "$tab" ] && echo "tab:  $tab"
