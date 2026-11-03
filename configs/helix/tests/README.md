# Helix ↔ Zed theme parity

`parity.py` checks that Helix's `duskfox` theme colors code the way Zed's
Duskfox does, in Python, Markdown, YAML, TOML, Rust, JavaScript, Swift, Go,
C and C++.

```bash
uv run configs/helix/tests/parity.py                  # all languages
uv run configs/helix/tests/parity.py swift go -v      # some, with accepted gaps
uv run configs/helix/tests/parity.py --theme /tmp/x.toml   # try a theme edit
```

Needs `uv` and `hx` on `PATH`. Dependencies are pinned in the script header.
A full run takes about a minute. It exits non-zero on a regression.

## How it works

For every non-blank character of each file in `samples/`:

- **Expected (Zed)**: the sample is parsed with tree-sitter and run through
  Zed's own highlight and injection queries (`zed/queries/`), then each
  capture resolves to a color from Zed's Duskfox syntax theme
  (`zed/duskfox.json`), following Zed's rules:
  - A capture maps to the longest dot-prefix theme key
    (`crates/syntax_theme/src/syntax_theme.rs`, `highlight_id`).
  - Captures with no key are skipped.
  - The last capture covering a character wins, ordered by
    (start, −end, layer depth, pattern index) (`crates/language/src/buffer.rs`
    `BufferChunks`; `crates/language/src/syntax_map.rs` `sort_key`).
  - Uncaptured text uses `editor.foreground`.
- **Actual (Helix)**: the real `hx` opens the sample in a pseudo-terminal with
  the theme, no gutter and LSP off. Each screen cell's color and bold/italic
  are read back with `pyte`.

Differences are grouped by (language, Zed capture, Helix color).
`known-gaps.toml` lists the accepted groups, each with a reason and the
character count it covered. A new group, or a known one that grows, fails the
run. A group that shrinks prints a note so its count can be lowered.

## Why gaps remain

Helix and Zed use different grammars' queries. Where Helix uses one scope for
things Zed colors differently, the theme picks the color that matches more
characters across all ten languages. Examples:

- `variable.parameter`: Helix colors every parameter use, Zed only the
  declaration, so parameters are plain.
- `namespace`: Python modules and Rust paths are plain in Zed, Go and C++
  namespaces are cyan; the plain side is larger.
- `keyword.control.import`: Python, Rust and Go imports are magenta, JS and
  Swift imports pink; magenta is larger.

The full list, with reasons, is in `known-gaps.toml`.

## Pinned sources

| Path | Source |
|------|--------|
| `zed/queries/{c,cpp,go,javascript,jsdoc,markdown,markdown-inline,python,regex,rust,yaml}` | `zed-industries/zed` `crates/grammars/src/*` at `v1.26.2` |
| `zed/queries/toml` | Zed `toml` extension 1.1.0 (as installed) |
| `zed/queries/swift` | `zed-extensions/swift` 0.4.11 (`302c7978`), the commit Zed's extension registry ships |
| `zed/duskfox.json` | `Duskfox - opaque` from the `nvim-nightfox` Zed extension 0.10.5 (`cange/nightfox.zed`) |

Zed parses JavaScript with the TSX grammar
(`crates/grammars/src/javascript/config.toml`), so the harness does too.
Grammars come from `tree-sitter-language-pack`, which can differ from the
revisions Zed pins. A Zed pattern using a node type the pack's grammar lacks
is skipped (`-v` lists them). Today that's only Swift's `"nil" @keyword`.

When Zed or Helix updates, re-vendor the queries, rerun, and update
`known-gaps.toml`.

## Limits

- Zed's semantic tokens are off by default (`semantic_tokens: "off"` in
  Zed's default settings) and aren't set in this repo's Zed config, so
  tree-sitter alone decides the colors in both editors. LSP is off in the
  Helix run too.
- The Zed side is computed, not screenshotted. Swift isn't installed in this
  Zed; its reference is the extension Zed would install.
- Samples use spaces, not tabs, so screen columns match source columns.
