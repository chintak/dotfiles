#!/usr/bin/env bash
# herdr-subagents — wait for a subagent to finish.
#
#   wait.sh <task> [extra herdr agent wait args…]
#
# Wraps `herdr agent wait`. Defaults: --until done --timeout 900000 (15 min).
# Override with UNTIL / TIMEOUT in the environment.
set -euo pipefail

if [ "${HERDR_ENV:-}" != 1 ]; then
  echo "wait.sh: requires HERDR_ENV=1 (run inside Herdr)" >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "usage: wait.sh <task> [herdr agent wait args…]" >&2
  exit 2
fi

task="$1"
shift

exec herdr agent wait "$task" \
  --until "${UNTIL:-done}" \
  --timeout "${TIMEOUT:-900000}" \
  "$@"
