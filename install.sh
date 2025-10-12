#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Linking Zsh configuration..."
ln -sf "${repo_dir}/.zshrc" "${HOME}/.zshrc"
ln -sf "${repo_dir}/.p10k.zsh" "${HOME}/.p10k.zsh"

echo "Done. Restart your terminal or run 'source ~/.zshrc' to load Powerlevel10k."
