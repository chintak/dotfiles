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
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.bash_profile"
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

current_shell="$(basename "${SHELL}")"
if [[ "${current_shell}" == "zsh" ]]; then
    echo "Detected shell: zsh"
    echo "Symlinking .zshrc.custom and sourcing from .zshrc..."
    ln -sf "${repo_dir}/zshrc.custom" "${HOME}/.zshrc.custom"
    if ! grep -q 'source ~/.zshrc.custom' "${HOME}/.zshrc" 2>/dev/null; then
        echo 'source ~/.zshrc.custom' >> "${HOME}/.zshrc"
    fi

elif [[ "${current_shell}" == "bash" ]]; then
    echo "Detected shell: bash"
    echo "Symlinking .bashrc.custom and sourcing from .bashrc..."
    ln -sf "${repo_dir}/bashrc.custom" "${HOME}/.bashrc.custom"
    if ! grep -q 'source ~/.bashrc.custom' "${HOME}/.bashrc" 2>/dev/null; then
        echo 'source ~/.bashrc.custom' >> "${HOME}/.bashrc"
    fi

else
    echo "Detected shell: ${current_shell}"
    echo "Symlinking .custom configuration for unsupported shell. Please adjust manually if needed."
fi

echo "Linking Cursor configuration..."
mkdir -p "${HOME}/.cursor"
# To link more configs in future, add them to the array below and loop over them.
configs_to_link=("mcp.json")
for config in "${configs_to_link[@]}"; do
    [ -f "${repo_dir}/.cursor/${config}" ] && ln -sf "${repo_dir}/.cursor/${config}" "${HOME}/.cursor/${config}"
done

echo "Done."
