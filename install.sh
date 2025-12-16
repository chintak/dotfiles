#!/usr/bin/env bash
# Exit immediately if any command exits with a non-zero status, and print each command before executing it (for easier debugging)
if [ -z "${BASH_VERSION:-}" ]; then
    exec /usr/bin/env bash "$0" "$@"
fi

set -e -x

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optionally install Homebrew if on macOS and it's missing
if [[ "$(uname)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "Homebrew already installed."
    fi
fi


# Install Starship prompt
echo "Installing Starship prompt..."
if ! command -v starship >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing Starship via Homebrew..."
        brew install starship
    else
        echo "Homebrew not found. Installing Starship via official installer..."
        sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
    fi
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

echo "Linking Cursor configuration..."
# Ensure ~/.cursor exists as a directory (not a symlink)
if [ -e "${HOME}/.cursor" ]; then
    if [ -L "${HOME}/.cursor" ]; then
        # It's a symlink, remove it to create a real directory
        rm "${HOME}/.cursor"
    fi
fi
mkdir -p "${HOME}/.cursor"

# Merge commands directory
if [ -d "${repo_dir}/.cursor/commands" ]; then
    if [ -e "${HOME}/.cursor/commands" ]; then
        if [ -L "${HOME}/.cursor/commands" ]; then
            # Remove existing symlink
            rm "${HOME}/.cursor/commands"
            ln -sf "${repo_dir}/.cursor/commands" "${HOME}/.cursor/commands"
        elif [ -d "${HOME}/.cursor/commands" ]; then
            # Existing directory: copy repo files that don't exist
            echo "Merging commands directory..."
            for cmd_file in "${repo_dir}/.cursor/commands"/*; do
                [ -f "$cmd_file" ] || continue
                cmd_name=$(basename "$cmd_file")
                if [ ! -e "${HOME}/.cursor/commands/${cmd_name}" ]; then
                    ln -sf "$cmd_file" "${HOME}/.cursor/commands/${cmd_name}"
                fi
            done
        fi
    else
        # Doesn't exist, create symlink
        ln -sf "${repo_dir}/.cursor/commands" "${HOME}/.cursor/commands"
    fi
    echo "Cursor commands merged."
fi

# Merge rules directory
if [ -d "${repo_dir}/.cursor/rules" ]; then
    if [ -e "${HOME}/.cursor/rules" ]; then
        if [ -L "${HOME}/.cursor/rules" ]; then
            # Remove existing symlink
            rm "${HOME}/.cursor/rules"
            ln -sf "${repo_dir}/.cursor/rules" "${HOME}/.cursor/rules"
        elif [ -d "${HOME}/.cursor/rules" ]; then
            # Existing directory: copy repo files that don't exist
            echo "Merging rules directory..."
            for rule_file in "${repo_dir}/.cursor/rules"/*; do
                [ -f "$rule_file" ] || continue
                rule_name=$(basename "$rule_file")
                if [ ! -e "${HOME}/.cursor/rules/${rule_name}" ]; then
                    ln -sf "$rule_file" "${HOME}/.cursor/rules/${rule_name}"
                fi
            done
        fi
    else
        # Doesn't exist, create symlink
        ln -sf "${repo_dir}/.cursor/rules" "${HOME}/.cursor/rules"
    fi
    echo "Cursor rules merged."
fi

# Link mcp.json if it exists in repo
if [ -f "${repo_dir}/.cursor/mcp.json" ]; then
    ln -sf "${repo_dir}/.cursor/mcp.json" "${HOME}/.cursor/mcp.json"
    echo "Cursor mcp.json linked."
fi

echo "Cursor configuration merged."

echo "Done."
