# glow

Renders markdown in the terminal. Used for reading agent output and repo docs
without leaving the pane (`glow README.md`, or `yazi` → Enter on a `.md`).

`glow.yml` keys (`style`, `width`, `pager`, `mouse`, `all`, `showLineNumbers`)
were taken from `glow --help`; if a future release renames them, the file
degrades to documentation and the env vars still work.

Theme: `dracula` — a glamour built-in, readable on the dark Ghostty terminal
(used by the CLI, the TUI pager, and the yazi preview pane / `Enter` opener).
Because glow on macOS resolves its config dir to
`~/Library/Preferences/glow/glow.yml` and never expands `~` in
`style:` paths, `zshrc` exports `GLOW_CONFIG_HOME=$HOME/.config/glow` plus
`GLOW_STYLE` (CLI) / `GLAMOUR_STYLE` (TUI) set to `dracula`.
`glow.yml` keeps `style: dracula` as the no-env fallback.
