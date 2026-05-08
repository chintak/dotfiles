# dotfiles

Development environment configuration: shell, terminal, and AI coding agent configs.

## Quick Start

```bash
git clone https://github.com/chintak/dotfiles ~/Documents/dotfiles
cd ~/Documents/dotfiles
./install.sh
```

After installation, restart your terminal or run `source ~/.zshrc`.

## What's Included

### Shell

| File | Description |
|------|-------------|
| `zshrc.custom` | Zsh config: Starship prompt, Homebrew, local secrets loading, `zj` alias for zellij |
| `starship.toml` | Starship prompt with Gruvbox Dark theme |

### Terminal

| Directory | Description |
|-----------|-------------|
| `ghostty/config` | Ghostty terminal config: Fira Code font, Gruvbox Dark Hard theme, optimized for agentic coding |
| `zellij/config.kdl` | Zellij multiplexer config: gruvbox theme, vim-style Alt keybindings, session persistence |
| `zellij/layouts/dev.kdl` | Dev layout: 70/30 editor+aux split with bottom terminal strip |
| `zellij/layouts/agents.kdl` | Multi-agent layout: 3 side-by-side panes + review tab |

### AI Coding Agent Configs

Reusable configs for AI coding assistants (Cursor, Claude Code, Codex). Managed via `skills-cli`.

| Directory | Description |
|-----------|-------------|
| `rules/` | AI assistant behavior rules (coding style, anti-slop guidelines) |
| `commands/` | Reusable prompt commands (commit conventions, docstring generation) |
| `skills/` | Agent skills and capabilities definitions |
| `agents/` | Agent configuration and persona definitions |

#### Available Configs

**Skills:**
- `ship` — Commit changes, push branch, and open or update a PR following Conventional Commits. Triggered by "ship", "ship it", "open a PR".
- `commit-and-sync` — Commit directly to the default branch, pull with rebase, and push — preserves linear history. Triggered by "commit and sync", "sync up".
- `google-docstrings` — Add Google-style docstrings to Python modules, classes, and functions. Triggered by "add docstrings", "document this function".

## skills-cli

A CLI tool for installing AI coding agent configs from this repo into project-level or user-level editor config directories.

### How It Works

```
dotfiles repo                          project directory
├── rules/                   install   ├── .cursor/skills/
├── commands/                -------->  │   ├── ship/
├── skills/                             │   └── google-docstrings/
│   ├── ship/                          ├── .claude/skills/
│   └── google-docstrings/         push        │   └── ship/
└── agents/                 <--------   └── .codex/skills/
                                            └── google-docstrings/
```

- **install** copies configs from the dotfiles repo into the project
- **push** copies configs from the project back into the dotfiles repo
- Automatically detects which editors are configured (`.cursor/`, `.claude/`, `.codex/`) and installs to all of them

### Usage

```
skills-cli <category> <action> [name] [flags]
```

**Categories:** `rules`, `commands`, `skills`, `agents`

**Actions:**

| Action | Description |
|--------|-------------|
| `list` (`ls`) | List available configs in the dotfiles repo |
| `install <name>` (`add`) | Copy a config into the project's editor dirs |
| `install --all` | Copy all configs in a category |
| `upgrade <name>` | Pull latest dotfiles and re-install a config |
| `remove <name>` (`rm`) | Delete an installed config from project editor dirs |
| `push <name>` | Copy a config from the project back into dotfiles |

There is also a top-level `skills-cli update` command that fetches and fast-forward pulls the dotfiles repo from its upstream remote. Run before `install` to ensure you have the latest configs (or use `upgrade`, which calls `update` automatically).

**Flags:**

| Flag | Description |
|------|-------------|
| `--level project` | Target the current directory (default) |
| `--level user` | Target `$HOME` for user-level config |
| `--force` | (push only) Overwrite existing entry in dotfiles |

### Examples

```bash
# List what's available
skills-cli skills list

# Install a single skill to the current project
skills-cli skills install ship

# Install all skills to the current project
skills-cli skills install --all

# Install a skill to user-level config (~/)
skills-cli skills install ship --level user

# Update a skill after changing it in dotfiles
skills-cli skills upgrade google-docstrings

# Remove a skill from the project
skills-cli skills remove google-docstrings

# Contribute a new skill from the project back to dotfiles
skills-cli skills push my-new-skill

# Overwrite an existing dotfiles entry
skills-cli skills push ship --force
```

### Editor Detection

When you run `skills-cli skills install google-docstrings` in a project directory, it checks for:

- `.cursor/` → installs to `.cursor/skills/google-docstrings/`
- `.claude/` → installs to `.claude/skills/google-docstrings/`
- `.codex/` → installs to `.codex/skills/google-docstrings/`

All detected editors receive the config. If none are found in the project, it falls back to checking `$HOME`.

## install.sh

The installer sets up the full development environment:

1. **Homebrew** — installs if missing (macOS)
2. **Starship** — installs prompt and links `starship.toml`
3. **Zsh** — symlinks `zshrc.custom` and sources it from `~/.zshrc`
4. **Ghostty** — copies terminal config to `~/Library/Application Support/com.mitchellh.ghostty/` (macOS only)
5. **GitHub CLI (`gh`)** — installs via Homebrew on macOS, official apt repo on Linux
6. **Zellij** — installs via the official launcher if missing, copies config and layouts to `~/.config/zellij/`
7. **skills-cli** — symlinks to `~/.local/bin/skills-cli`

## Zellij Quick Reference

The `zj` alias (defined in `zshrc.custom`) starts or attaches to a directory-named session:

```bash
cd ~/projects/myapp
zj              # creates/attaches to session "myapp"
zj other-name   # creates/attaches to session "other-name"
```

**Key bindings** (all single-chord, no prefix key):

| Binding | Action |
|---------|--------|
| `Alt+h/j/k/l` | Navigate between panes (vim-style) |
| `Alt+n` | New pane (auto-split) |
| `Alt+d` / `Alt+r` | New pane below / right |
| `Alt+w` | Close pane |
| `Alt+f` | Toggle fullscreen zoom |
| `Alt+t` | New tab |
| `Alt+1-5` | Jump to tab by number |
| `Alt+[` / `Alt+]` | Previous / next tab |
| `Alt+=` / `Alt+-` | Resize pane |
| `Alt+z` | Toggle pane frames |

## Local Secrets

Machine-specific environment variables (API keys, tokens) go in `~/.config/localenvs/*.local` files. These are sourced automatically by `zshrc.custom` and should not be committed.

```bash
mkdir -p ~/.config/localenvs
echo 'export MY_API_KEY="sk-xxx"' > ~/.config/localenvs/myservice.local
```
