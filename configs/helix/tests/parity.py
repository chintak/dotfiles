# /// script
# requires-python = ">=3.11"
# dependencies = ["tree-sitter==0.26.0", "tree-sitter-language-pack==1.23.1", "pyte==0.8.2"]
# ///
"""Theme parity: does Helix's duskfox theme color code the way Zed does?

For each sample in samples/, every non-blank character gets two colors:

- Zed (expected): the sample is parsed with tree-sitter and Zed's own
  highlight queries (vendored in zed/queries/), then resolved through Zed's
  Duskfox syntax colors (zed/duskfox.json) using Zed's rules:
  * a capture name maps to the longest theme key that is a dot-prefix of it
    (crates/syntax_theme/src/syntax_theme.rs, `highlight_id`); captures with
    no key are dropped, so whatever is underneath shows through;
  * captures are ordered by (start, -end, layer depth, pattern index) and the
    last one covering a character wins (crates/language/src/buffer.rs,
    BufferChunks highlight stack; syntax_map.rs `sort_key`);
  * injections (markdown inline, fenced code, regex, jsdoc, ...) are parsed
    as deeper layers;
  * uncaptured text uses the theme's editor foreground.
- Helix (actual): the real `hx` renders the sample in a pseudo-terminal
  with the repo's theme, no gutter and no LSP, and each screen cell's color
  is read back with pyte.

Differences are grouped by (language, Zed capture, Helix color). Groups
listed in known-gaps.toml are accepted up to their recorded `count`; a new
group, or a known one that grows, fails the run.

    uv run configs/helix/tests/parity.py                # all languages
    uv run configs/helix/tests/parity.py rust python -v # some, with detail
"""
from __future__ import annotations

import argparse, collections, fcntl, json, os, pty, re, select, shutil, struct
import subprocess, sys, tempfile, termios, time, tomllib
from dataclasses import dataclass, field
from pathlib import Path

import pyte
import tree_sitter as ts
import tree_sitter_language_pack as tslp

HERE = Path(__file__).resolve().parent
THEME = HERE.parent / "files" / "themes" / "duskfox.toml"
COLS, ROWS = 220, 140

# sample file -> (Zed query dir, tree-sitter grammar)
LANGS = {
    "python": ("sample.py", "python"),
    "markdown": ("sample.md", "markdown"),
    "yaml": ("sample.yaml", "yaml"),
    "toml": ("sample.toml", "toml"),
    "rust": ("sample.rs", "rust"),
    "javascript": ("sample.js", "javascript"),
    "swift": ("sample.swift", "swift"),
    "go": ("sample.go", "go"),
    "c": ("sample.c", "c"),
    "cpp": ("sample.cpp", "cpp"),
}
# Zed query dir -> tree-sitter-language-pack grammar
# Zed parses JavaScript with the TSX grammar (crates/grammars/src/javascript/config.toml).
GRAMMAR = {"markdown-inline": "markdown_inline", "jsdoc": "jsdoc",
           "regex": "regex", **{k: k for k in LANGS}, "javascript": "tsx"}
# names used by injections (fence info strings, #set! injection.language)
ALIASES = {"py": "python", "python3": "python", "rs": "rust", "js": "javascript", "jsx": "javascript",
           "yml": "yaml", "c++": "cpp", "golang": "go", "markdown_inline": "markdown-inline"}


# ── Zed side ─────────────────────────────────────────────────────────────

def split_patterns(src: str) -> list[str]:
    """Split a .scm query into its top-level patterns, keeping their order."""
    out, cur, depth, i, n = [], [], 0, 0, len(src)
    def flush():
        s = "".join(cur).strip()
        if s:
            out.append(s)
        cur.clear()
    while i < n:
        c = src[i]
        if c == ";":                                   # comment to end of line
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if depth == 0 and (m := re.match(r"[A-Za-z_][\w-]*\s*:", src[i:])):
            flush()                                    # top-level `field: node` pattern
            cur.append(m.group(0)); i += m.end()
            continue
        starts_node = depth == 0 and "".join(cur).strip() and not "".join(cur).strip().endswith(":")
        if c == '"':                                   # string literal
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
            if starts_node:
                flush()
            cur.append(src[i:j + 1]); i = j + 1
            continue
        if c in "([":
            if starts_node:
                flush()
            depth += 1
        elif c in ")]":
            depth -= 1
        cur.append(c); i += 1
    flush()
    # A pattern's trailing "@capture" / quantifiers were split off when they
    # follow a closing bracket at depth 0; glue them back on.
    merged: list[str] = []
    for p in out:
        if merged and re.match(r"^[@*+?]", p):
            merged[-1] += " " + p
        else:
            merged.append(p)
    return merged


@dataclass
class QuerySet:
    query: ts.Query
    index: list[int]                                   # compiled pattern -> index in the .scm file
    skipped: list[str] = field(default_factory=list)


_query_cache: dict[tuple[str, str], QuerySet | None] = {}


def load_queries(lang: str, kind: str) -> QuerySet | None:
    """Compile a Zed query file whole, as Zed does (predicates may name
    captures from other patterns). Patterns using node types this grammar
    version lacks are dropped one at a time; pattern order is preserved."""
    key = (lang, kind)
    if key in _query_cache:
        return _query_cache[key]
    path = HERE / "zed" / "queries" / lang / f"{kind}.scm"
    if not path.exists() or lang not in GRAMMAR:
        _query_cache[key] = None
        return None
    language = tslp.get_language(GRAMMAR[lang])
    # Lua patterns only differ from regex in ways these queries don't use.
    pats = [p.replace("#lua-match?", "#match?") for p in split_patterns(path.read_text())]
    keep, skipped = [], []
    for i, pat in enumerate(pats):
        try:
            # A fresh copy: on error, py-tree-sitter overwrites newlines in the
            # string it was given with NULs.
            ts.Query(language, pat + "\n")
            keep.append(i)
        except Exception as e:
            msg = str(e).splitlines()[0]
            if "capture name" in msg:                  # names a capture from another pattern
                keep.append(i)
            else:                                      # grammar drift: node/field unknown here
                skipped.append(f"{msg[:50]} | {' '.join(pat.split())[:60]}")
    q = ts.Query(language, "\n\n".join(pats[i] for i in keep))
    qs = QuerySet(q, keep, skipped)
    _query_cache[key] = qs
    return qs


@dataclass(order=True)
class Cap:
    start: int
    neg_end: int
    depth: int
    pattern: int
    name: str = field(compare=False)
    lang: str = field(compare=False)


def parse(lang: str, src: bytes, ranges: list[ts.Range] | None = None) -> ts.Tree:
    parser = ts.Parser(tslp.get_language(GRAMMAR[lang]))
    if ranges:
        parser.included_ranges = ranges
    return parser.parse(src)


def collect(lang: str, src: bytes, depth: int, ranges, out: list[Cap], skipped: dict, seen=0):
    hl = load_queries(lang, "highlights")
    if hl is None:
        skipped.setdefault(lang, ["(no Zed highlights for this language)"])
        return
    if hl.skipped:
        skipped.setdefault(lang, hl.skipped)
    tree = parse(lang, src, ranges)
    root = tree.root_node
    for pix, caps in ts.QueryCursor(hl.query).matches(root):
        ix = hl.index[pix]
        for name, nodes in caps.items():
            if name.startswith("_"):
                continue
            for node in nodes:
                out.append(Cap(node.start_byte, -node.end_byte, depth, ix, name, lang))
    inj = load_queries(lang, "injections")
    if inj is None or seen > 4:
        return
    for pix, caps in ts.QueryCursor(inj.query).matches(root):
        content = caps.get("injection.content", [])
        if "injection.language" in caps:            # e.g. a fence's info string
            n = caps["injection.language"][0]
            target = src[n.start_byte:n.end_byte].decode().strip().lower()
        else:                                       # (#set! injection.language "x")
            target = (inj.query.pattern_settings(pix) or {}).get("injection.language")
        if not target or not content:
            continue
        target = ALIASES.get(target, target)
        if target not in GRAMMAR or not (HERE / "zed" / "queries" / target).exists():
            skipped.setdefault(f"{lang}->{target}", ["(injected language not modelled)"])
            continue
        for node in content:
            rng = [ts.Range(node.start_point, node.end_point, node.start_byte, node.end_byte)]
            collect(target, src, depth + 1, rng, out, skipped, seen + 1)


def theme_lookup(syntax: dict, name: str):
    """Zed's highlight_id: the longest theme key that is a dot-prefix of name."""
    best = None
    for key in syntax:
        if name == key or name.startswith(key + "."):
            if best is None or len(key) > len(best):
                best = key
    return best


def zed_colors(lang: str, src: bytes, theme: dict) -> tuple[list, dict]:
    caps: list[Cap] = []
    skipped: dict = {}
    collect(lang, src, 0, None, caps, skipped)
    fg = theme["editor_foreground"].lower()[:7]
    per = [(fg, False, False, None)] * len(src)
    for c in sorted(caps):
        key = theme_lookup(theme["syntax"], c.name)
        if key is None:
            continue                                  # not pushed in Zed either
        st = theme["syntax"][key]
        color = st.get("color", theme["editor_foreground"]).lower()[:7]
        italic = st.get("font_style") == "italic"
        bold = (st.get("font_weight") or 400) >= 700
        for b in range(c.start, -c.neg_end):
            per[b] = (color, bold, italic, c.name)
    return per, skipped


# ── Helix side ───────────────────────────────────────────────────────────

class Screen(pyte.Screen):
    def __init__(self, cols, rows, fd):
        super().__init__(cols, rows)
        self._fd = fd

    def write_process_input(self, data):              # answer terminal queries
        try:
            os.write(self._fd, data.encode())
        except OSError:
            pass


HELIX_CONFIG = """
theme = "duskfox"
[editor]
gutters = []
cursorline = false
bufferline = "never"
color-modes = false
auto-info = false
soft-wrap = { enable = false }
indent-guides = { render = false }
lsp = { enable = false }
"""


def helix_screen(sample: Path, theme: Path) -> pyte.Screen:
    hx = shutil.which("hx")
    if not hx:
        sys.exit("parity: `hx` not found on PATH")
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / "helix" / "themes").mkdir(parents=True)
        (tmp / "helix" / "config.toml").write_text(HELIX_CONFIG)
        shutil.copy(theme, tmp / "helix" / "themes" / "duskfox.toml")
        work = tmp / "work"; work.mkdir()
        target = work / sample.name
        shutil.copy(sample, target)
        env = {**os.environ, "XDG_CONFIG_HOME": str(tmp), "TERM": "xterm-256color",
               "COLORTERM": "truecolor"}
        pid, fd = pty.fork()
        if pid == 0:
            os.chdir(work)
            os.execve(hx, [hx, target.name], env)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLS, 0, 0))
        screen = Screen(COLS, ROWS, fd)
        stream = pyte.ByteStream(screen)
        start = last = time.time()
        while time.time() - start < 15:
            r, _, _ = select.select([fd], [], [], 0.2)
            if r:
                try:
                    data = os.read(fd, 65536)
                except OSError:
                    break
                if not data:
                    break
                stream.feed(data)
                last = time.time()
            elif time.time() - last > 1.5 and time.time() - start > 2.5:
                break
        os.write(fd, b"\x1b")                          # alone, or it reads as alt+:
        time.sleep(0.2)
        os.write(fd, b":q!\r")
        deadline = time.time() + 5
        while time.time() < deadline:
            r, _, _ = select.select([fd], [], [], 0.2)
            if r:
                try:
                    if not os.read(fd, 65536):
                        break
                except OSError:
                    break
        if os.waitpid(pid, os.WNOHANG) == (0, 0):     # still running: don't hang
            os.kill(pid, 9)
            os.waitpid(pid, 0)
        os.close(fd)
        return screen


def hexcolor(c: str) -> str:
    return "#" + c.lower() if re.fullmatch(r"[0-9a-fA-F]{6}", c or "") else str(c)


# ── comparison ───────────────────────────────────────────────────────────

@dataclass
class Gap:
    count: int = 0
    tokens: list = field(default_factory=list)


def compare(lang: str, theme: dict, styles: bool, helix_theme: Path):
    fname, _ = LANGS[lang]
    sample = HERE / "samples" / fname
    src = sample.read_bytes()
    zed, skipped = zed_colors(lang, src, theme)
    screen = helix_screen(sample, helix_theme)
    lines = src.split(b"\n")
    gaps: dict[tuple, Gap] = collections.defaultdict(Gap)
    total = ok = 0
    offset = 0
    for row, line in enumerate(lines):
        if row >= ROWS - 2:
            break
        if b"\t" in line:
            sys.exit(f"parity: {fname}:{row + 1} has a tab; samples must use spaces")
        for col, ch in enumerate(line):
            b = offset + col
            if chr(ch).isspace() or col >= COLS or (row == 0 and col == 0):
                continue                               # (0,0) holds the cursor
            cell = screen.buffer[row][col]
            zc, zb, zi, zname = zed[b]
            hc = hexcolor(cell.fg)
            total += 1
            bad = hc != zc or (styles and (bool(cell.bold) != zb or bool(cell.italics) != zi))
            if not bad:
                ok += 1
                continue
            key = (lang, zname or "(none)", zc + ("/b" if zb else "") + ("/i" if zi else ""),
                   hc + ("/b" if cell.bold else "") + ("/i" if cell.italics else ""))
            g = gaps[key]
            g.count += 1
            lo = col
            while lo > 0 and (chr(line[lo - 1]).isalnum() or line[lo - 1] == ord("_")):
                lo -= 1
            word = re.match(rb"[\w!]+|\S", line[lo:])
            tok = word.group(0).decode(errors="replace")
            if tok not in g.tokens and len(g.tokens) < 6:
                g.tokens.append(tok)
        offset += len(line) + 1
    return total, ok, gaps, skipped


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("langs", nargs="*", metavar="LANG", help=f"any of: {', '.join(LANGS)} (default: all)")
    ap.add_argument("-v", "--verbose", action="store_true", help="also list accepted gaps and skipped query patterns")
    ap.add_argument("--theme", type=Path, default=THEME, help="Helix theme to test (default: the repo's duskfox.toml)")
    ap.add_argument("--no-styles", action="store_true", help="compare colors only, ignore bold/italic")
    args = ap.parse_args()
    if bad := [l for l in args.langs if l not in LANGS]:
        ap.error(f"unknown language(s): {', '.join(bad)}")
    theme = json.loads((HERE / "zed" / "duskfox.json").read_text())
    known = tomllib.loads((HERE / "known-gaps.toml").read_text()).get("gap", [])
    used = [False] * len(known)
    failed = False
    for lang in args.langs or LANGS:
        total, ok, gaps, skipped = compare(lang, theme, not args.no_styles, args.theme)
        unexpected = []
        for key, g in sorted(gaps.items(), key=lambda kv: -kv[1].count):
            hit = next((i for i, k in enumerate(known)
                        if k["lang"] in (lang, "*") and k["zed"] == key[1] and k["helix"] == key[3]), None)
            if hit is None or g.count > known[hit].get("count", 0):
                unexpected.append((key, g))
                if hit is not None:
                    used[hit] = True
            else:
                used[hit] = True
                if g.count < known[hit].get("count", 0):
                    print(f"note: {lang} {key[1]} -> {key[3]} shrank to x{g.count} "
                          f"(accepted x{known[hit]['count']}); lower its count")
                if args.verbose:
                    print(f"  accepted {lang:10} {key[1]:28} zed {key[2]:12} helix {key[3]:12} x{g.count:<3} {' '.join(g.tokens)}")
        pct = 100 * ok / total if total else 0
        status = "FAIL" if unexpected else "ok"
        print(f"{status:4} {lang:10} {ok}/{total} chars match ({pct:.1f}%), "
              f"{len(gaps)} gap group(s), {len(unexpected)} unexpected")
        for key, g in unexpected:
            base = next((k.get("count", 0) for k in known if k["lang"] in (lang, "*")
                         and k["zed"] == key[1] and k["helix"] == key[3]), None)
            grew = f" (accepted x{base})" if base is not None else ""
            print(f"     {key[1]:28} zed {key[2]:12} helix {key[3]:12} x{g.count:<3}{grew} {' '.join(g.tokens)}")
        if args.verbose:
            for where, pats in skipped.items():
                print(f"  skipped {where}: {len(pats)} Zed pattern(s) this grammar can't compile")
                for p in pats[:8]:
                    print(f"           {p}")
        failed |= bool(unexpected)
    if not args.langs:
        for k, u in zip(known, used):
            if not u:
                print(f"note: known gap no longer seen: {k['lang']} {k['zed']} -> {k['helix']}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
