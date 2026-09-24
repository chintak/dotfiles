# helix

The editor for browsing and editing *inside panes*. Chosen over nvim here
because it needs no plugin manager: it auto-detects and starts LSP servers found
on `PATH`.

`languages.toml` only pins what auto-detection gets wrong (Python, Lua).
`$EDITOR=hx` is set in `zshrc`; `git config` uses `core.editor = hx`.

## Markdown writing

`soft-wrap` fills the pane width with full indent retention; Enter continues
lists, quotes and task boxes (`comment-tokens` trick — note `1.` does not
increment to `2.`, and `space c` line-comments with `-` in markdown).

Tooling (see `Brewfile`): `marksman` (LSP), `harper-ls` (offline spell +
grammar; code actions on `space a` add words to
`~/.config/harper-ls/dictionary.txt`), `prettier` (format on save).
Helix has no built-in spell checker yet (spellbook PR pending) — harper is
the LSP route.

Preview: `space m p` runs `gh markdown-preview` (browser, live reloads on
save); needs `gh extension install yusukebe/gh-markdown-preview`.
`glow <file>` is the pane-rendered alternative. Theme: `onelight`.

Word motion: `alt+left/right` (and `cmd+left/right` via Home/End) in insert
and normal mode. `shift+alt+left/right` is owned by herdr (tab focus) and
never reaches hx inside a pane; it's still bound to word motion as a fallback
for hx sessions outside herdr. Known shadowing inside herdr panes
(`alt+d/u/i/n` go to herdr, not hx) is documented in `config.toml`.

Code browsing = `hx <worktree>` in a pane, or `yazi` → Enter.
