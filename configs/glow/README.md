# glow

Renders markdown in the terminal. Used for reading agent output and repo docs
without leaving the pane (`glow README.md`, or `yazi` → Enter on a `.md`).

`glow.yml` keys (`style`, `width`, `pager`, `mouse`, `all`, `showLineNumbers`)
were taken from `glow --help`; if a future release renames them, the file
degrades to documentation and the env vars still work.

Theme: `onelight.json` — a glamour style built from hx's `onelight` palette
(headings red→gold→yellow→green→blue→purple, bold yellow, italic purple, links
cyan/light-blue, inline code green on grey). Because glow on macOS resolves its
config dir to `~/Library/Preferences/glow/glow.yml` and never expands `~` in
`style:` paths, `zshrc` exports `GLOW_CONFIG_HOME=$HOME/.config/glow` plus
`GLOW_STYLE` (CLI) / `GLAMOUR_STYLE` (TUI) pointing at the file with an absolute
path. `glow.yml` keeps `style: auto` as the no-env fallback.
