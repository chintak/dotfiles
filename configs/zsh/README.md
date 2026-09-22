# zsh

Single shell config for macOS and Linux. Notable choices:

- **Prompt switching lives here, not in two configs.** `STARSHIP_CONFIG` is set
  from `$SSH_CONNECTION`/`$SSH_TTY`, so one repo serves the Mac (powerline) and
  the phone (glyph-free) without duplication.
- **Tool integrations are guarded** (`(( $+commands[x] ))`), so the same file is
  valid on a box where zoxide/atuin/direnv/mise aren't installed.
- **Plugin order matters**: zsh-autosuggestions, then zsh-syntax-highlighting
  **last**. Both are sourced through `_zsh_share` so the Linuxbrew path works.
- **herdr hook**: renames the tab to the running command, falling back to the
  directory. This is why the herdr sidebar reads `pytest`, not `zsh`.
- Machine-specific bits go in `~/.zshrc.local` (never committed).
