# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

local_env_dir="${XDG_CONFIG_HOME:-$HOME/.config}/envs"
if [[ -d "$local_env_dir" ]]; then
  # Load tool-specific environment variables (local only).
  for env_file in "$local_env_dir"/*.env; do
    [[ -f "$env_file" ]] || continue
    source "$env_file"
  done
fi
unset local_env_dir env_file

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# zsh options: http://zsh.sourceforge.net/Doc/Release/Options.html
setopt APPEND_HISTORY # adds history
setopt HIST_IGNORE_ALL_DUPS # If a new command line being added to the history list duplicates an older one, the older command is removed from the list
setopt HIST_IGNORE_SPACE # No history when starting command with space
setopt HIST_SAVE_NO_DUPS # When writing out the history file, older commands that duplicate newer ones are omitted

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

export ZSH=~/.oh-my-zsh

ZSH_THEME="powerlevel10k/powerlevel10k"
source $ZSH/oh-my-zsh.sh
prompt_context(){}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias proxyemr='autossh -M0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -N -D 18080 tick'

alias nebula-console=/Users/csheth/Documents/nebula-console-darwin-arm64-v3.8.0
export NEBULA_GRAPH_ADDRESS=beta-nebula-graphd-thrift.service.ash1.consul
export NEBULA_GRAPH_PORT=9669
# alias nebula-console-login=nebula-console -addr $NEBULA_GRAPH_ADDRESS -port $NEBULA_GRAPH_PORT -u root -p nebula
