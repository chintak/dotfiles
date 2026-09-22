#!/usr/bin/env bash
# dot.worktree — pane "board".
# Live task table: `dot` streams the board, refreshing every 2s.
set -euo pipefail

DOT="${DOT_BIN:-dot}"
HERDR="${HERDR_BIN_PATH:-herdr}"   # injected by Herdr; dot reads it too
WS="${HERDR_WORKSPACE_ID:-}"       # current workspace (dot resolves it itself)
PANE="${HERDR_PANE_ID:-}"          # this overlay pane

exec "$DOT" task list --watch
