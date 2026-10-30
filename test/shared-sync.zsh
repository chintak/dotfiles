#!/usr/bin/env zsh
# shared-sync.zsh — guard the write-once contract for shared/ (AGENTS.md,
# skills, MCP servers) across the opencode and claude packages:
#   1. both packages link AGENTS.md and skills from shared/, never copies
#   2. every shared skill has a claude manifest entry, and none are stale
#   3. the rendered MCP configs match shared/mcp.json
set -euo pipefail
ROOT="${0:A:h:h}"
fail=0
err() { print -u2 "FAIL $*"; fail=1; }

for pkg in opencode claude; do
  for f in AGENTS.md skills; do
    p="$ROOT/configs/$pkg/files/$f"
    [[ -L "$p" && "$(readlink "$p")" == ../../../shared/$f ]] || err "configs/$pkg/files/$f must symlink to ../../../shared/$f"
  done
done

mf="$ROOT/configs/claude/manifest"
want=(${(f)"$(cd "$ROOT/shared/skills" && for d in */; do print -r -- "${d%/}"; done | sort)"})
have=(${(f)"$(sed -n 's#^file *= *skills/\([^|]*\)|.*#\1#p' "$mf" | sort)"})
[[ "${want[*]}" == "${have[*]}" ]] || err "claude manifest skills (${have[*]}) != shared/skills (${want[*]})"

python3 "$ROOT/shared/render-mcp.py" --check || err "rendered MCP config is stale"

(( fail == 0 )) && print "shared-sync: AGENTS.md, skills, and MCP config are shared and in sync"
exit $fail
