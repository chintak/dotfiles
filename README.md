# dotfiles

Shell, terminal, and multiplexer config for macOS and Linux (incl. remote
GPU boxes). One repo, symlinked into place, so a fix on the Mac is a fix
everywhere.

## Bootstrap a new machine

```bash
git clone https://github.com/chintak/dotfiles ~/git/dotfiles
~/git/dotfiles/install.sh
exec zsh
```

`install.sh` is idempotent and symlink-based: it links files into
`~/.config` (never copies), backs up anything it replaces as
`*.bak.<timestamp>`, runs `brew bundle` on macOS, and installs the Python
CLIs via `uv`. Re-run it any time.

## Layout

| Path | Links to | Notes |
|------|----------|-------|
| `zshrc` | `~/.zshrc` | shell: PATH, history, fzf, prompt, helpers |
| `starship.toml` | `~/.config/starship.toml` | desktop powerline prompt |
| `starship.mobile.toml` | `~/.config/starship.mobile.toml` | glyph-free prompt for SSH/iOS |
| `ghostty/config` | `~/.config/ghostty/config` | macOS terminal (hands chords to herdr) |
| `herdr/config.toml` | `~/.config/herdr/config.toml` | agent multiplexer |
| `zellij/` | `~/.config/zellij/` | alternative multiplexer + layouts |
| `skills/` | — | agent skills, installed by `skills-cli` |
| `bin/skills-cli` | `~/.local/bin/skills-cli` | skill installer |
| `Brewfile` | — | macOS package manifest |

## Two prompts, one theme

`zshrc` picks the prompt from the environment:

- **Local** (Ghostty) → `starship.toml`, the powerline prompt.
- **Over SSH** (`$SSH_CONNECTION`/`$SSH_TTY`, or Termius) →
  `starship.mobile.toml`, a single-line prompt with no Nerd Font glyphs.

Nerd Font icons live in Unicode's Private Use Area, which has no OS font
fallback — on a phone whose font lacks them they render as tofu boxes.
The mobile prompt avoids them entirely and drops the right prompt (it
wraps badly at ~43 columns). Both use the same Dracula palette as the
terminal and herdr.

## Secrets

Machine-local env vars (keys, tokens) go in
`~/.config/localenvs/*.local` or `~/.env`; both are git-ignored and
sourced automatically. Non-secret per-host overrides go in
`~/.zshrc.local`.

## Notes

- Ghostty reads **two** config paths on macOS. `install.sh` moves a stale
  file at `~/Library/Application Support/com.mitchellh.ghostty/config`
  aside, otherwise it silently overrides `~/.config/ghostty/config`.
- `skills-cli` installs skills from `skills/` into a project's
  `.cursor/`, `.claude/`, or `.codex/` directory:
  `skills-cli skills install ship`.
