# starship

Two profiles, one palette, chosen at runtime by `zshrc`.

- `starship.toml` — desktop powerline (directory → git → languages).
- `starship.mobile.toml` — **glyph-free**, single line, no right prompt.

Why two: Nerd Font icons live in Unicode's Private Use Area, which has **no OS
font fallback**. On a client whose font lacks them they render as tofu boxes,
and a right prompt wraps badly at ~43 columns. The server sending the bytes is
irrelevant — the phone draws the pixels.

Keep the module lists in sync when you add one. Both use the Dracula palette to
match Ghostty and herdr.
