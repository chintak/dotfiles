# yazi

File manager with inline previews — useful for watching agents mutate files.

- Previews images and PDFs inline. PDFs need `poppler`'s `pdftoppm`; `chafa` is
  the fallback for terminals without a graphics protocol (Ghostty has one).
- `Enter` opens with the right opener: `hx` for code, `glow` for markdown,
  the system viewer for PDFs/images.
- Markdown previews render through the official `piper.yazi` plugin
  (vendored in `files/piper.yazi`, sourced from yazi-rs/plugins@main) shelling
  out to `glow` with glamour's built-in `dracula` style (readable on the
  dark Ghostty terminal). The command in `yazi.toml` sets `CLICOLOR_FORCE=1`
  (piper pipes glow's output), pins `-s dracula` explicitly (an env-set
  style alone makes glow fall back to notty when not a tty, and relying on
  the parent env makes the theme depend on how yazi was launched), and
  `PAGER=cat` so glow's `pager: true` doesn't run `less` in the pane.
- UI theme is the upstream `tokyo-night` flavor
  (BennyOe/tokyo-night.yazi, pinned at `8e6296f`, vendored in
  `files/flavors/tokyo-night.yazi` like `piper.yazi` — declarative, no
  `ya pkg add`), selected via `[flavor] dark` in `theme.toml`, which keeps
  only local overrides (row highlight, empty status separators).
- Openers use yazi's `%s` shell formatting — `$@` was deprecated in yazi 26
  and stopped passing the file to `hx`.
- `e` edits in Helix; `y` yanks the path.

Needs the terminal to expose a graphics protocol — Ghostty does
(`kitty_graphics = true` in `herdr/config.toml`).
