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
choices: the theme overrides scopes so that Zed's Rust grammar plus Duskfox's
syntax colors come out the same here. That means every keyword is one
magenta, types and enum variants are yellow, fields are blue, and paths and
lifetimes are plain text. One known gap: Helix captures `derive` as
`special`, the scope `?` also uses, so `#[derive(` stays in the punctuation
color where Zed draws it blue italic.

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

Code browsing = `hx <worktree>` in a pane, or `yazi` → Enter.
