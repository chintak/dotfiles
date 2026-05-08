#!/usr/bin/env bash
# Exit immediately if any command exits with a non-zero status, and print each command before executing it (for easier debugging)
if [ -z "${BASH_VERSION:-}" ]; then
    exec /usr/bin/env bash "$0" "$@"
fi

set -e -x

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
os="$(uname -s)"

# Optionally install Homebrew if on macOS and it's missing
if [[ "$os" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Homebrew already installed."
    fi
fi

# Install Starship prompt to ~/.local/bin to avoid sudo
echo "Installing Starship prompt..."
if ! command -v starship >/dev/null 2>&1; then
    mkdir -p "${HOME}/.local/bin"
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "${HOME}/.local/bin"
else
    echo "Starship already installed."
fi

# Link Starship configuration
echo "Linking Starship configuration..."
mkdir -p "${HOME}/.config"
if [ -f "${repo_dir}/starship.toml" ]; then
    ln -sf "${repo_dir}/starship.toml" "${HOME}/.config/starship.toml"
    echo "Starship config linked."
else
    echo "Warning: starship.toml not found in repo."
fi

# Setup zsh configuration
echo "Setting up zsh configuration..."
if [[ "$(basename "${SHELL}")" != "zsh" ]]; then
    echo "Warning: Current shell is not zsh. This installer is designed for zsh."
    echo "Please switch to zsh and run this installer again, or manually configure zsh."
fi

echo "Symlinking .zshrc.custom and sourcing from .zshrc..."
ln -sf "${repo_dir}/zshrc.custom" "${HOME}/.zshrc.custom"
if ! grep -q 'source ~/.zshrc.custom' "${HOME}/.zshrc" 2>/dev/null; then
    echo 'source ~/.zshrc.custom' >> "${HOME}/.zshrc"
    echo "Added source line to ~/.zshrc"
else
    echo "Source line already present in ~/.zshrc"
fi

# Install Ghostty configuration (macOS only)
if [[ "$os" == "Darwin" ]]; then
    echo "Installing Ghostty configuration..."
    ghostty_dest="${HOME}/Library/Application Support/com.mitchellh.ghostty"
    mkdir -p "${ghostty_dest}"
    cp "${repo_dir}/ghostty/config" "${ghostty_dest}/config"
    echo "Ghostty config copied to ${ghostty_dest}/config"
fi

# Install GitHub CLI
echo "Installing GitHub CLI..."
if ! command -v gh >/dev/null 2>&1; then
    if [[ "$os" == "Darwin" ]]; then
        # macOS: no official curl installer, use Homebrew
        if command -v brew >/dev/null 2>&1; then
            brew install gh
        else
            echo "Warning: Install gh manually: https://cli.github.com"
        fi
    else
        # Linux: official install script
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update && sudo apt-get install -y gh
    fi
else
    echo "GitHub CLI already installed."
fi

# Install Zellij
echo "Installing Zellij..."
if ! command -v zellij >/dev/null 2>&1; then
    # Official installer supports macOS and Linux
    bash <(curl -fsSL https://zellij.dev/launch)
else
    echo "Zellij already installed."
fi

# Install Zellij configuration
echo "Installing Zellij configuration..."
zellij_dest="${XDG_CONFIG_HOME:-$HOME/.config}/zellij"
mkdir -p "${zellij_dest}/layouts"
cp "${repo_dir}/zellij/config.kdl" "${zellij_dest}/config.kdl"
cp "${repo_dir}/zellij/layouts/dev.kdl" "${zellij_dest}/layouts/dev.kdl"
cp "${repo_dir}/zellij/layouts/agents.kdl" "${zellij_dest}/layouts/agents.kdl"
echo "Zellij config and layouts copied to ${zellij_dest}/"

# Install skills-cli
echo "Installing skills-cli..."
mkdir -p "${HOME}/.local/bin"
ln -sf "${repo_dir}/bin/skills-cli" "${HOME}/.local/bin/skills-cli"
echo "skills-cli linked to ~/.local/bin/skills-cli"

echo "Done."
echo ""
echo "Use 'skills-cli' to manage coding agent configs (rules, commands, skills, agents)."
echo "Run 'skills-cli help' for usage."
