# helix

The editor for browsing and editing *inside panes*. Chosen over nvim here
because it needs no plugin manager: it auto-detects and starts LSP servers found
on `PATH`.

`languages.toml` only pins what auto-detection gets wrong (Python, Lua).
`$EDITOR=hx` is set in `zshrc`; `git config` uses `core.editor = hx`.

## Theme

`theme = "duskfox"` (`themes/duskfox.toml`): Helix's built-in `nightfox`
theme with the Duskfox palette from Zed's nvim-nightfox extension, matching
Zed and Rex. Helix 25.07.1 can't follow the terminal's light/dark mode (its
`[theme] dark/light` table exists only on unreleased master), so Helix stays
dark even when Rex is on Dayfox.

Syntax colors follow what Zed actually renders, not nightfox's scope
choices. `tests/parity.py` checks this for Python, Markdown, YAML, TOML, Rust,
JavaScript, Swift, Go, C and C++ (see [tests/README.md](tests/README.md)):

```bash
uv run configs/helix/tests/parity.py        # all ten languages
uv run configs/helix/tests/parity.py rust -v
```

Run it after any change to `themes/duskfox.toml`.

## Auto-save

Every modified buffer is written ~1s after the last change and on focus loss,
never mid-insert (Esc only flushes a queued timer save; `after-delay`-only).
Formatting is skipped; `prettier` runs on a manual `:w` only. An agent's edit
fails the save loudly (`file modified by an external process, use :w!`) — F5
reloads, `:w!` the trap. `hx` is `$EDITOR`: abort a commit or `rebase -i` with
`:cq!`, never `:q!`. herdr focus forwarding is unverified; the timer covers it.

## Markdown writing

`soft-wrap` fills the pane width with full indent retention; Enter continues
lists, quotes and task boxes (`comment-tokens` trick — note `1.` does not
increment to `2.`, and `space c` line-comments with `-` in markdown).

Tooling (see `Brewfile`): `marksman` (LSP), `harper-ls` (offline spell +
grammar; code actions on `space a` add words to
`~/.config/harper-ls/dictionary.txt`), `prettier` (format on a manual `:w`;
autosave skips formatting).
Helix has no built-in spell checker yet (spellbook PR pending) — harper is
the LSP route.

Preview: `space m p` runs `gh markdown-preview` (browser, live reloads on
save); needs `gh extension install yusukebe/gh-markdown-preview`.

Word motion: `alt+left/right` (and `cmd+left/right` via Home/End) in insert
and normal mode. `shift+alt+left/right` is owned by herdr (tab focus) and
never reaches hx inside a pane; it's still bound to word motion as a fallback
for hx sessions outside herdr. Known shadowing inside herdr panes
(`alt+d/u/i/n` go to herdr, not hx) is documented in `config.toml`.

LSP docs on demand: `g q` (alias for the default `space k` hover) opens the
docs for the symbol under the cursor; there is no hover-on-idle option.
Signature help pops up on its own while typing arguments.

Symbol search: `space s` = current-file symbols; `space S` = project-wide
(workspace) symbols. In the workspace picker an empty prompt shows
nothing (helix never sends the empty query). The text before any `%column`
goes to rust-analyzer; `%column` terms filter its results in helix (fzf
syntax). Tested on helix 25.07.1 + rust-analyzer 1.98.1:

| Query | Finds |
|---|---|
| `area`, `circ`, `maxrad` | in-order subsequence of the name |
| `shapes::area`, `shapes::` | items in module `shapes` (first segment: crate or top-level module, exact) |
| `geom::MAX` | items at crate `geom`'s root |
| `area %c Circle` / `area %c !Circle` | by container (impl type, enum, trait) |
| `a %k function`, `a %k !package` | by kind; `!package` drops crate-name rows |
| `a %p ^app` | by path prefix (bare `%p app` also matches `…/aarch64-apple-…`) |
| `*HashMap` | include std/dependencies |
| `::`, `::geom` | crates |

Lowercase query letters match either case, uppercase only uppercase
(`circle` finds `Circle`, `CIRCLE` doesn't). Spaces and fzf operators
(`^ $ ' !`) only work after a `%column`. Paths follow definitions, not
re-exports (`geom::shapes::Circle`, not `geom::Circle`), and can't go through
types (`Circle::area` finds nothing; use `area %c Circle`). Struct fields
aren't indexed; `__`-prefixed names need a `__` query.

Code browsing = `hx <worktree>` in a pane, or `yazi` → Enter.
