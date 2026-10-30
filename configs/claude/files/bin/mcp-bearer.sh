#!/bin/sh
# headersHelper for Claude Code MCP servers: mcp-bearer.sh <VAR> prints
# {"Authorization": "Bearer <token>"}. Token lookup, first hit wins:
#   1. $VAR in the environment
#   2. login keychain item "dot-mcp-<VAR>"
#      (security add-generic-password -U -a "$USER" -s dot-mcp-<VAR> -w)
#   3. the OpenCode daemon env, when opencode is installed
var="${1:?usage: mcp-bearer.sh <VAR>}"
tok="$(printenv "$var")"
[ -n "$tok" ] || tok="$(security find-generic-password -a "$USER" -s "dot-mcp-$var" -w 2>/dev/null)"
[ -n "$tok" ] || ! command -v opencode >/dev/null || tok="$(opencode service get env "$var" 2>/dev/null)"
[ -n "$tok" ] || { echo "mcp-bearer: $var not found (env, keychain dot-mcp-$var, opencode service env)" >&2; exit 1; }
printf '{"Authorization": "Bearer %s"}\n' "$tok"
