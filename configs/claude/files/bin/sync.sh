#!/usr/bin/env bash
# post_apply for the claude config: reconcile user-scope MCP servers in
# ~/.claude.json with mcp.json (rendered from shared/mcp.json). Idempotent;
# only touches servers it manages.
set -euo pipefail

DIR="$HOME/.config/dot/claude"
STATE="$DIR/.managed-mcp"   # servers this script added last run

command -v claude >/dev/null || { echo "claude: CLI not found, skipping" >&2; exit 0; }

# ── MCP servers ─────────────────────────────────────────────────────────
desired="$(sed "s|\$HOME|$HOME|g" "$DIR/mcp.json" | jq -c '.mcpServers')"
current() { jq -c --arg n "$1" '.mcpServers[$n] // empty' "$HOME/.claude.json" 2>/dev/null || true; }

for name in $(jq -r 'keys[]' <<<"$desired"); do
  want="$(jq -cS --arg n "$name" '.[$n]' <<<"$desired")"
  have="$(current "$name" | jq -cS . 2>/dev/null || true)"
  [[ "$want" == "$have" ]] && continue
  [[ -n "$have" ]] && claude mcp remove -s user "$name" >/dev/null
  claude mcp add-json -s user "$name" "$want" >/dev/null
  echo "claude: mcp $name registered"
done

# drop servers we added before that mcp.json no longer lists
if [[ -f "$STATE" ]]; then
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    jq -e --arg n "$name" 'has($n)' <<<"$desired" >/dev/null && continue
    if [[ -n "$(current "$name")" ]]; then
      claude mcp remove -s user "$name" >/dev/null
      echo "claude: mcp $name removed"
    fi
  done < "$STATE"
fi
jq -r 'keys[]' <<<"$desired" > "$STATE"
