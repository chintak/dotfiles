#!/usr/bin/env bash
# Exit immediately if any command exits with a non-zero status, and print each command before executing it (for easier debugging)
set -e -x

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

current_shell="$(basename "${SHELL}")"
if [[ "${current_shell}" == "zsh" ]]; then
    echo "Detected shell: zsh"
    if [ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
        echo "Oh My Zsh not found, installing..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "Oh My Zsh already installed at ${ZSH:-$HOME/.oh-my-zsh}."
    fi
    # Install Powerlevel10k if not already present
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$P10K_DIR" ]; then
        echo "Installing Powerlevel10k (p10k) theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${P10K_DIR}"
    else
        echo "Powerlevel10k already installed at ${P10K_DIR}."
    fi
    echo "Symlinking .zshrc.custom and sourcing from .zshrc..."
    ln -sf "${repo_dir}/zshrc.custom" "${HOME}/.zshrc.custom"
    if ! grep -q 'source ~/.zshrc.custom' "${HOME}/.zshrc" 2>/dev/null; then
        echo 'source ~/.zshrc.custom' >> "${HOME}/.zshrc"
    fi
    ln -sf "${repo_dir}/p10k.zsh" "${HOME}/.p10k.zsh"

elif [[ "${current_shell}" == "bash" ]]; then
    echo "Detected shell: bash"
    if [ ! -d "${OSH:-$HOME/.oh-my-bash}" ]; then
        echo "Oh My Bash not found, installing..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    else
        echo "Oh My Bash already installed at ${OSH:-$HOME/.oh-my-bash}."
    fi
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
