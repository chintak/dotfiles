#!/usr/bin/env bash
# herdr-subagents — read a subagent's recent output.
#
#   collect.sh <task> [extra herdr agent read args…]
#
# Wraps `herdr agent read`. Defaults: --source recent-unwrapped --lines 200.
# Override with SOURCE / LINES in the environment.
set -euo pipefail

if [ "${HERDR_ENV:-}" != 1 ]; then
  echo "collect.sh: requires HERDR_ENV=1 (run inside Herdr)" >&2
  exit 1
fi

if [ "$#" -lt 1 ]; then
  echo "usage: collect.sh <task> [herdr agent read args…]" >&2
  exit 2
fi

task="$1"
shift

exec herdr agent read "$task" \
  --source "${SOURCE:-recent-unwrapped}" \
  --lines "${LINES:-200}" \
  "$@"
