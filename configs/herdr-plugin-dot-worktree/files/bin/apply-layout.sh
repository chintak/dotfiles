#!/usr/bin/env bash
# dot.worktree — action "apply-layout" and the `worktree.created` hook.
# Idempotently reconcile the review + web tabs and task panes (§8.3).
set -euo pipefail

DOT="${DOT_BIN:-dot}"
HERDR="${HERDR_BIN_PATH:-herdr}"   # injected by Herdr; dot reads it too
WS="${HERDR_WORKSPACE_ID:-}"       # current workspace (dot resolves it itself)
PANE="${HERDR_PANE_ID:-}"          # calling pane

exec "$DOT" up
