# starship

Two profiles, one palette, chosen at runtime by `zshrc`.

- `starship.toml` — desktop: TokyoNight powerline path pill + flat conditional
  git/language tags on line 1; line 2 carries exit code / command duration /
  background jobs (the agentic-dev readouts). No dead segments outside repos.
- `starship.mobile.toml` — **glyph-free**, single line, no right prompt, same
  module set as the desktop twin (including the line-1 transient tail).

Why two: Nerd Font icons live in Unicode's Private Use Area, which has **no OS
font fallback**. On a client whose font lacks them they render as tofu boxes,
and a right prompt wraps badly at ~43 columns. The server sending the bytes is
irrelevant — the phone draws the pixels.

Keep the module lists in sync when you add one. Both use the TokyoNight palette to
match Ghostty.
