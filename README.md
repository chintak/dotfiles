# dotfiles

Environment configuration for interactive shells, with additional support for Cursor editor settings.

## What's Included

- `install.sh`: Automatically detects your current shell, installs Powerlevel10k if using zsh, and creates the necessary configuration symlinks in your home directory.
- `zshrc.custom`: Configuration for Oh My Zsh with Powerlevel10k theme, Homebrew setup, Nebula console helpers, and automatic loading of local secrets.
- `bashrc.custom`: Configuration for Oh My Bash including theme selection, plugin and alias setup, enhanced shell history options, and local secrets loader.
- `p10k.zsh`: Profile file for the Powerlevel10k prompt used by `zshrc.custom`.
- `.cursor/mcp.json`: Configuration file for MCP server lists, used by the Cursor editor.

## How to Use

1. From the root of this repository, run `./install.sh` to set up or update configuration symlinks.
2. After installation, restart your terminal or run `source ~/.zshrc` (for zsh) or `source ~/.bashrc` (for bash) to apply the configuration.


## Notes

- Key features:
  - On macOS, `install.sh` can automatically install Homebrew before setting up your shell.
  - `install.sh` will automatically install Oh My Zsh (for zsh) or Oh My Bash (for bash) if they're not already present.
  - Shell history is set to append commands immediately with timestamps, so your session history is always up to date.
  - Secret and machine-specific environment variables can be defined in `~/.config/localenvs/*.local` files, which are loaded automatically by both shell configs. This keeps sensitive data out of the main repo.
  - The installer adds lines to source the managed config files (`.zshrc.custom` or `.bashrc.custom`) only if they aren't already present, keeping your rc files tidy.
  - Cursor settings are placed in the `.cursor/` directory. To link additional configs, add them to the installer list.
