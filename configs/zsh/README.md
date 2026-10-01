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
- **`dot` completion hook**: the zshrc adds the `dot` completions dir to
  `fpath` **before** `compinit` (fpath must be final when compinit scans it,
  or `_dot` never autoloads). Preference order: dev checkout
  (`~/git/dotfiles/completions`), the bootstrap clone
  (`~/.local/share/dot/repo/completions`), then the bootstrap-installed copy
  (`~/.local/share/dot/completions/_dot`).
- **zcompdump rescan is deterministic, not doc-only**: the manifest's
  `post_apply` removes `~/.zcompdump`, and the 1.3.0 → 1.4.0 version bump
  changes `applyHash`, so the one-time rescan (picking up the new fpath
  hook) happens exactly when this version lands. `dot apply --force-post`
  re-runs it any time.
- Machine-specific bits go in `~/.zshrc.local` (never committed).
