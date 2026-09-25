# zsh

Single shell config for macOS and Linux. Notable choices:

- **Prompt switching lives here, not in two configs.** `STARSHIP_CONFIG` is set
  from `$SSH_CONNECTION`/`$SSH_TTY`, so one repo serves the Mac (powerline) and
  the phone (glyph-free) without duplication.
- **Tool integrations are guarded** (`(( $+commands[x] ))`), so the same file is
  valid on a box where zoxide/atuin/direnv/mise aren't installed.
- **Plugin order matters**: zsh-autosuggestions, then zsh-syntax-highlighting
  **last**. Both are sourced through `_zsh_share` so the Linuxbrew path works.
- **herdr TERM fix**: inside herdr (`HERDR_ENV=1`), `TERM` is rewritten from
  `xterm-256color` to `tmux-256color` so TUI apps render correctly. herdr's
  default tab names are kept — no renaming on shell commands.
- **alt+left/right word jumps**: zle binds Ghostty's CSI encodings
  (`\e[1;3C`/`\e[1;3D`) so the chords forwarded by Ghostty/herdr work at the
  prompt, not just inside Helix.
- Machine-specific bits go in `~/.zshrc.local` (never committed).
