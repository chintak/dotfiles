# ~/.zshrc — symlinked from ~/git/dotfiles. Edit the repo, not this file.
# One config for macOS + Linux. Machine-specific bits: ~/.zshrc.local.

# ── PATH + Homebrew ────────────────────────────────────────────────────
typeset -U path fpath PATH
path=("$HOME/.local/bin" "$HOME/bin" "$HOME/.opencode/bin" /usr/local/bin $path)
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [[ -x "$_brew" ]] && { eval "$("$_brew" shellenv)"; break }
done
unset _brew

# ── locale ─────────────────────────────────────────────────────────────
export LANG=${LANG:-en_US.UTF-8} LC_ALL=${LC_ALL:-en_US.UTF-8}

# ── secrets (never committed) ──────────────────────────────────────────
[[ -r "$HOME/.env" ]] && source "$HOME/.env"
for _f in "${XDG_CONFIG_HOME:-$HOME/.config}"/localenvs/*.local(N); do source "$_f"; done
unset _f

# ── history ────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history HISTSIZE=100000 SAVEHIST=100000
setopt APPEND_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS SHARE_HISTORY

# ── completion ─────────────────────────────────────────────────────────
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS GLOB_COMPLETE

# ── fzf (fd as the engine) ─────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --exclude node_modules'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --exclude node_modules'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline --cycle'
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || head -200 {}' --preview-window right:60%:wrap"
export FZF_ALT_C_OPTS="--preview 'find {} -maxdepth 2 -type d | head -50' --preview-window right:50%"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap --bind 'ctrl-_:toggle-preview'"
export FZF_COMPLETION_TRIGGER='**'
[[ -o interactive && -t 0 && -t 1 ]] && (( $+commands[fzf] )) && source <(fzf --zsh)

# ── prompt: glyph-free over SSH, powerline locally ─────────────────────
if [[ -n "$SSH_CONNECTION$SSH_TTY" || "$TERM_PROGRAM" == "Termius" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship.mobile.toml"
else
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi
(( $+commands[starship] )) && eval "$(starship init zsh)"

# ── optional tools (no-op when absent) ─────────────────────────────────
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[atuin] ))  && eval "$(atuin init zsh --disable-up-arrow)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"
(( $+commands[mise] ))   && eval "$(mise activate zsh)"
export EDITOR="${EDITOR:-nvim}"

# ── herdr: name the tab after the running command ──────────────────────
[[ ${HERDR_ENV:-0} == 1 && "$TERM" == "xterm-256color" ]] && export TERM=tmux-256color
if [[ -n "$HERDR_TAB_ID" && -n "$HERDR_BIN_PATH" ]]; then
  _herdr_tab_rename() { "$HERDR_BIN_PATH" tab rename "$HERDR_TAB_ID" "$1" >/dev/null 2>&1 &! }
  _herdr_tab_preexec() { local cmd="${1%% *}"; _herdr_tab_rename "${${cmd:t}:0:24}" }
  _herdr_tab_precmd()  { local dir="${PWD/#$HOME/~}"; _herdr_tab_rename "${dir##*/}" }
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _herdr_tab_preexec
  add-zsh-hook precmd  _herdr_tab_precmd
fi

# ── helpers ────────────────────────────────────────────────────────────
zj() { zellij attach "${1:-${PWD:t}}" 2>/dev/null || zellij --session "${1:-${PWD:t}}"; }
leo-agent() { docker exec -it -w /workspace leo-gateway /opt/hermes/.venv/bin/hermes "$@"; }
[[ -S /tmp/hermes-ssh-agent/socket ]] && export SSH_AUTH_SOCK=/tmp/hermes-ssh-agent/socket
export NEBULA_GRAPH_ADDRESS=alpha-nebula-graphd-thrift.service.ash1.consul
export NEBULA_GRAPH_PORT=9669
alias nebula-console-login="nebula-console -addr $NEBULA_GRAPH_ADDRESS -port $NEBULA_GRAPH_PORT -u root -p nebula"

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ── plugins (syntax-highlighting must be sourced last) ─────────────────
_zsh_share() {
  local root
  for root in /opt/homebrew/share /usr/local/share /home/linuxbrew/.linuxbrew/share; do
    [[ -r "$root/$1" ]] && { source "$root/$1"; return; }
  done
}
_zsh_share zsh-autosuggestions/zsh-autosuggestions.zsh
_zsh_share zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unfunction _zsh_share
