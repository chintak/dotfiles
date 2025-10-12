#!/usr/bin/env bash
set -euo pipefail
set -x

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Backing up existing  configuration..."
mv "${HOME}/.zshrc" "${HOME}/.zshrc.bak"

echo "Linking Zsh configuration..."
ln -sf "${repo_dir}/.zshrc" "${HOME}/.zshrc"
ln -sf "${repo_dir}/.p10k.zsh" "${HOME}/.p10k.zsh"
ln -sf "${repo_dir}/.cursor/mcp.json" "${HOME}/.cursor/mcp.json"

echo "Done. Restart your terminal or run 'source ~/.zshrc' to load Powerlevel10k."
