# dotfiles

Environment configuration for interactive shells and Cursor tooling.

## What's Included

- `install.sh` – detects your active shell, installs Powerlevel10k for zsh, and links the managed configs into `$HOME`.
- `zshrc.custom` – Oh My Zsh setup with Powerlevel10k, Homebrew environment, Nebula console helpers, and local secret loading.
- `bashrc.custom` – Oh My Bash theme selection, plugin/alias list, extended history settings, and local secret loading.
- `p10k.zsh` – Powerlevel10k prompt profile referenced by `zshrc.custom`.
- `.cursor/mcp.json` – tailored MCP server list for Cursor.

## Usage

1. Ensure [Oh My Zsh](https://ohmyz.sh) (for zsh) or [Oh My Bash](https://github.com/ohmybash/oh-my-bash) is installed as needed.
2. Run `./install.sh` from the repo root to create or refresh the symlinks.
3. Restart your terminal, or source the relevant rc file (`source ~/.zshrc` or `source ~/.bashrc`) to pick up the managed configuration.

## Notes

- `install.sh` safely appends sourcing lines to existing rc files without duplicating entries.
- Shell configs source any `~/.config/tools/*.local` files, letting you keep API keys and machine-specific settings out of the repo.
- `bashrc.custom` enables timestamped, append-only history so commands persist immediately across sessions.
- Cursor settings live under `.cursor/`; add new MCP configs there and extend the script loop if more files need linking.
