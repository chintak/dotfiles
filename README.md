# dotfiles

Environment configuration for interactive shells, with additional support for Cursor editor settings.

## What's Included

### Shell Configuration
- `install.sh`: Installs Starship prompt and sets up zsh configuration with necessary symlinks.
- `zshrc.custom`: Configuration for zsh with Starship prompt, Homebrew setup, Nebula console helpers, and automatic loading of local secrets.
- `starship.toml`: Configuration file for the Starship prompt with Gruvbox Dark theme and custom format.

### Cursor Editor Configuration
- `.cursor/mcp.json`: MCP server configuration for Git, Sequential Thinking, and Context7 integrations.
- `.cursor/rules/`: Workspace rules for Cursor AI assistant (e.g., `deslop.mdc`, `python-development.mdc`).
- `.cursor/commands/`: Custom Cursor commands (e.g., `commit.md`, `docstrings.md`).

## How to Use

1. From the root of this repository, run `./install.sh` to set up or update configuration symlinks.
2. After installation, restart your terminal or run `source ~/.zshrc` to apply the configuration.


## Notes

- Key features:
  - On macOS, `install.sh` can automatically install Homebrew before setting up your shell.
  - `install.sh` automatically installs Starship prompt (via Homebrew on macOS, or official installer otherwise).
  - Shell history is configured to append commands immediately with timestamps, so your session history is always up to date.
  - Secret and machine-specific environment variables can be defined in `~/.config/localenvs/*.local` files, which are loaded automatically by the zsh config. This keeps sensitive data out of the main repo.
  - The installer adds a line to source `.zshrc.custom` in your `~/.zshrc` only if it isn't already present, keeping your rc files tidy.
  - Starship configuration is linked to `~/.config/starship.toml` with a Gruvbox Dark theme preset.
  - Cursor editor configuration:
    - The installer merges commands and rules from the dotfiles repo with any existing `~/.cursor/` directory.
    - If `~/.cursor/commands` or `~/.cursor/rules` don't exist, they are symlinked from the repo.
    - If they already exist as directories, individual files from the repo are symlinked into them (preserving existing files).
    - `mcp.json` is always symlinked from the repo, making MCP configuration, rules, and commands available globally for all Cursor-based development.
