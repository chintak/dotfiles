#!/usr/bin/env bash
# Dotfiles installer — idempotent, symlink-based, macOS + Linux.
# Symlinks (never copies) so edits in the repo apply immediately, everywhere.
#
#   git clone https://github.com/chintak/dotfiles ~/git/dotfiles
#   ~/git/dotfiles/install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
STAMP="$(date +%Y%m%d-%H%M%S)"
shopt -s nullglob

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*"; }

# link <source> <target> — backs up any existing non-symlink target once.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    warn "backing up $dst -> $dst.bak.$STAMP"
    mv "$dst" "$dst.bak.$STAMP"
  fi
  ln -s "$src" "$dst"
  log "linked $dst"
}

log "dotfiles: $DOTFILES ($OS)"

# ── shell ───────────────────────────────────────────────────────────────
link "$DOTFILES/zshrc" "$HOME/.zshrc"
[[ -L "$HOME/.zshrc.custom" ]] && { rm -f "$HOME/.zshrc.custom"; log "removed legacy ~/.zshrc.custom"; }

# ── prompts ─────────────────────────────────────────────────────────────
link "$DOTFILES/starship.toml"        "$HOME/.config/starship.toml"
link "$DOTFILES/starship.mobile.toml" "$HOME/.config/starship.mobile.toml"

# ── terminal (macOS only) ───────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  link "$DOTFILES/ghostty/config" "$HOME/.config/ghostty/config"
  # Ghostty also reads this path; a leftover file there silently overrides
  # ~/.config. Move it out of the way.
  LEGACY="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  if [[ -e "$LEGACY" && ! -L "$LEGACY" ]]; then
    mv "$LEGACY" "$LEGACY.stale.$STAMP"
    warn "moved stale Ghostty config -> $LEGACY.stale.$STAMP"
  fi
fi

# ── multiplexer ─────────────────────────────────────────────────────────
link "$DOTFILES/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link "$DOTFILES/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
for layout in "$DOTFILES"/zellij/layouts/*.kdl; do
  link "$layout" "$HOME/.config/zellij/layouts/$(basename "$layout")"
done

# ── bin ─────────────────────────────────────────────────────────────────
[[ -f "$DOTFILES/bin/skills-cli" ]] && link "$DOTFILES/bin/skills-cli" "$HOME/.local/bin/skills-cli"

# ── prompt binary (no sudo; same path on Linux) ─────────────────────────
if ! command -v starship >/dev/null 2>&1; then
  log "installing starship -> ~/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"
fi

# ── packages ────────────────────────────────────────────────────────────
if [[ "${SKIP_BREW:-0}" != 1 ]] && [[ "$OS" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
  log "brew bundle"
  brew bundle --file "$DOTFILES/Brewfile" || warn "brew bundle reported failures (continuing)"
fi

# Python CLIs are installed with uv so they're identical on every machine.
if command -v uv >/dev/null 2>&1; then
  for tool in ruff pytest nvitop huggingface_hub; do
    uv tool install --quiet "$tool" >/dev/null 2>&1 || true
  done
fi

log "done — run: exec zsh"
