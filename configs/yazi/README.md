# yazi

File manager with inline previews — useful for watching agents mutate files.

- Previews images and PDFs inline. PDFs need `poppler`'s `pdftoppm`; `chafa` is
  the fallback for terminals without a graphics protocol (Ghostty has one).
- `Enter` opens with the right opener: `hx` for code, `glow` for markdown,
  the system viewer for PDFs/images.
- Markdown previews render through the vendored `glow.yazi` plugin
  (`files/glow.yazi`, adapted from yazi-rs/plugins piper.yazi) shelling out
  to `glow` with the One Light theme from `configs/glow`. The plugin sets
  `CLICOLOR_FORCE=1` (the preview pipes glow's output), passes
  `-s=$GLOW_STYLE` explicitly (an env-set style alone makes glow fall back
  to notty when not a tty), and `PAGER=cat` so glow's `pager: true` doesn't
  run `less` in the pane.
- `e` edits in Helix; `y` yanks the path.

Needs the terminal to expose a graphics protocol — Ghostty does
(`kitty_graphics = true` in `herdr/config.toml`).
