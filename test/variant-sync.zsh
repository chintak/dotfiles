#!/usr/bin/env zsh
# variant-sync.zsh — guard against drift between the opencode config and
# its mac-work variant: `opencode-work.jsonc` must equal `opencode.jsonc`
# with the `mcp` block removed. Both are JSONC (comments, trailing commas),
# so parse them with a string-aware comment stripper + trailing-comma
# cleanup, then compare the resulting structures.
#
# Edit opencode.jsonc? This test fails until opencode-work.jsonc gets the
# same change (modulo mcp). Both files also carry leading comments
# explaining the pairing — keep the new file's top comment intact.

emulate -L zsh

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
DEFAULT="$ROOT/configs/opencode/files/opencode.jsonc"
VARIANT="$ROOT/configs/opencode/files/opencode-work.jsonc"

for f in "$DEFAULT" "$VARIANT"; do
  [[ -f "$f" ]] || { print -u2 "FAIL missing $f"; exit 1; }
done

command -v python3 >/dev/null 2>&1 || {
  print -u2 "FAIL python3 not found (needed to parse JSONC)"
  exit 1
}

python3 - "$DEFAULT" "$VARIANT" <<'PY'
import json, re, sys


def strip_jsonc(text):
    """Remove // and /* */ comments, preserving their contents inside strings."""
    out, i, n, in_str = [], 0, len(text), False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def load_jsonc(path):
    s = strip_jsonc(open(path).read())
    s = re.sub(r",(\s*[}\]])", r"\1", s)  # trailing commas
    return json.loads(s)


default, variant = load_jsonc(sys.argv[1]), load_jsonc(sys.argv[2])
default.pop("mcp", None)

if default == variant:
    print("variant-sync: opencode-work.jsonc == opencode.jsonc minus mcp")
    sys.exit(0)

print("FAIL opencode-work.jsonc drifted from opencode.jsonc (minus mcp):", file=sys.stderr)
for key in sorted(set(default) | set(variant)):
    d, v = default.get(key, "<absent>"), variant.get(key, "<absent>")
    if d != v:
        print(f"  key {key!r}:", file=sys.stderr)
        print(f"    opencode.jsonc      {json.dumps(d, indent=2)}", file=sys.stderr)
        print(f"    opencode-work.jsonc {json.dumps(v, indent=2)}", file=sys.stderr)
sys.exit(1)
PY
