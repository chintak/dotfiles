# dotfiles

One repo for the whole terminal development environment — shell, prompt,
terminal, multiplexer, agent tooling — on macOS, iOS-over-SSH, and remote
GPU boxes (Hetzner / RunPod). Everything is **symlinked** into place, so a
fix committed here is a fix on every machine.

Read this top to bottom once — it's the map. Each section links to the
upstream docs so you can go deeper on anything unfamiliar.

## Contents

- [Philosophy](#philosophy)
- [Bootstrap a new machine](#bootstrap-a-new-machine)
- [Repo layout](#repo-layout)
- [How the installer works](#how-the-installer-works)
- [The stack, layer by layer](#the-stack-layer-by-layer)
- [Toolchain by project](#toolchain-by-project)
- [Daily workflow](#daily-workflow)
- [Working across machines](#working-across-machines)
- [Secrets & per-host overrides](#secrets--per-host-overrides)
- [Learn more (links)](#learn-more)
- [Gotchas](#gotchas)

---

## Philosophy

Three rules hold the whole thing together:

1. **One multiplexer layer.** [herdr](https://herdr.dev/docs) owns panes,
   tabs, and workspaces *everywhere* — Mac, phone, VPS. [Ghostty](https://ghostty.org/docs)
   and Termius are just fast renderers. Never stack Ghostty splits + herdr
   panes + tmux; pick one. The one exception is an unsupervised multi-day
   job, which runs in `tmux` *underneath* a herdr pane (see
   [tmux](#tmux--the-long-running-exception)).

2. **Symlinks, never copies.** `install.sh` links files into `~/.config`
   rather than copying them. Edit the repo → every machine sees it on the
   next `git pull`. This is why the old copy-based installer was replaced.

3. **One theme.** [Dracula](https://draculatheme.com/) across Ghostty,
   Starship, and herdr, so the terminal is visually coherent. The palette
   lives in three places; keep them in sync.

The design goal is **low-latency, glyph-safe, and identical on every
client** — including a 43-column iPhone screen over a flaky cellular link.

---

## Bootstrap a new machine

```bash
git clone https://github.com/chintak/dotfiles ~/git/dotfiles
~/git/dotfiles/install.sh
exec zsh
```

- `SKIP_BREW=1 ~/git/dotfiles/install.sh` links configs but installs no
  packages (useful on a server you don't want a full toolchain on).
- Re-running is always safe: it backs up anything it replaces as
  `*.bak.<timestamp>`.
- Update an existing machine with `git -C ~/git/dotfiles pull && ~/git/dotfiles/install.sh`.

---

## Repo layout

| Path | Symlinked to | What it is |
|------|--------------|------------|
| `zshrc` | `~/.zshrc` | The shell: PATH, history, fzf, prompt switch, helpers |
| `starship.toml` | `~/.config/starship.toml` | Desktop prompt (powerline) |
| `starship.mobile.toml` | `~/.config/starship.mobile.toml` | Glyph-free prompt for SSH / iOS |
| `ghostty/config` | `~/.config/ghostty/config` | macOS terminal (hands chords to herdr) |
| `herdr/config.toml` | `~/.config/herdr/config.toml` | Agent multiplexer |
| `zellij/config.kdl` + `zellij/layouts/*.kdl` | `~/.config/zellij/` | Alternative multiplexer + layouts |
| `skills/` | — | Agent skills, installed by `skills-cli` |
| `bin/skills-cli` | `~/.local/bin/skills-cli` | Skill installer (see [skills-cli](#skills-cli)) |
| `Brewfile` | — | macOS package manifest |
| `install.sh` | — | The installer |

> The repo lives at `~/git/dotfiles` (not `~/Documents/…`) because code and
> dotfiles belong outside iCloud Drive — see [Gotchas](#gotchas).

---

## How the installer works

`install.sh` is ~85 lines of bash. The interesting part is one function:

```bash
# link <source> <target> — backs up any existing non-symlink target once.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then rm -f "$dst"                 # replace old symlink
  elif [[ -e "$dst" ]]; then mv "$dst" "$dst.bak.$STAMP" # back up a real file
  fi
  ln -s "$src" "$dst"
}
```

Then it:

1. Links every config in [the layout table](#repo-layout).
2. Removes the legacy `~/.zshrc.custom` symlink if present.
3. On macOS, moves a stale `~/Library/Application Support/com.mitchellh.ghostty/config`
   aside (see [Gotchas](#gotchas)).
4. Installs [Starship](https://starship.rs/guide/) into `~/.local/bin` if
   missing (no `sudo`).
5. Runs [`brew bundle`](https://docs.brew.sh/Brewfile) from the `Brewfile`
   (skippable with `SKIP_BREW=1`).
6. Installs Python CLIs with [`uv tool install`](https://docs.astral.sh/uv/guides/tools/)
   so they are identical on every machine.

`Brewfile` covers the OS-level tools; Python tools go through `uv`, not
Homebrew, so they don't fight over interpreters.

---

## The stack, layer by layer

### Shell — [zsh](https://zsh.sourceforge.io/Doc/)

`zshrc` is the single shell config (macOS + Linux). It sets:

- **PATH**: `~/.local/bin`, `~/bin`, `~/.opencode/bin`, plus whichever
  Homebrew prefix exists (Apple Silicon, Intel, or Linuxbrew).
- **History**: 100k lines, `SHARE_HISTORY` so all open shells see each
  other's commands immediately.
- **fzf**: uses [`fd`](https://github.com/sharkdp/fd) as the file engine
  and [`bat`](https://github.com/sharkdp/bat) for previews — respects
  `.gitignore`, so `Ctrl-T` never offers you `node_modules`.
- **Tool integrations**, each guarded so it's a no-op when the tool is
  absent: [`zoxide`](https://github.com/ajeetdsouza/zoxide) (smart `cd`),
  [`atuin`](https://atuin.sh/docs) (synced shell history),
  [`direnv`](https://direnv.net/) (per-directory env),
  [`mise`](https://mise.jdx.dev/) (per-project runtimes).
- **herdr hook**: renames the tab to the running command, falling back to
  the directory name — so the sidebar reads `pytest`, `rojo`, `nvim`.
- **Helpers**: `zj` (attach/create a zellij session named after the cwd),
  `leo-agent`, and the NebulaGraph console alias.

Plugin order matters and is commented in the file:
[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
first, [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
**last**.

### Prompt — [Starship](https://starship.rs/guide/)

Two profiles, one theme, chosen automatically in `zshrc`:

```zsh
if [[ -n "$SSH_CONNECTION$SSH_TTY" || "$TERM_PROGRAM" == "Termius" ]]; then
  export STARSHIP_CONFIG="$HOME/.config/starship.mobile.toml"
else
  export STARSHIP_CONFIG="$HOME/.config/starship.toml"
fi
```

- **Desktop** (`starship.toml`) — powerline segments: directory → git →
  language versions. Uses Nerd Font glyphs, which is fine on the Mac.
- **Mobile** (`starship.mobile.toml`) — **glyph-free**, single line, no
  right prompt. Nerd Font icons live in Unicode's
  [Private Use Area](https://en.wikipedia.org/wiki/Private_Use_Areas),
  which has **no OS font fallback** — on a client whose font lacks them
  they render as tofu boxes (`□□□`). The server sending the bytes is
  irrelevant; the phone draws the pixels. See
  [Nerd Fonts](https://www.nerdfonts.com/) and
  [why PUA has no fallback](https://termai.sh/blog/mobile-terminal-fonts-glyphs).

Keep the two files' module lists in sync when you add one.

### Terminal — [Ghostty](https://ghostty.org/docs)

Ghostty is the renderer only. Two jobs:

1. **Hand its own chords to herdr.** Ghostty's native split/tab shortcuts
   are `unbind`-ed so herdr receives them. In 1.3.x the native Split menu
   can win over `unbind`, so split chords are emitted as explicit
   [Kitty keyboard-protocol](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)
   CSI-u sequences (`performable:super+d=text:…`). This is the least
   obvious part of the whole setup — read the comments in `ghostty/config`.
2. **Comfort**: Dracula, 100 MB scrollback (agents emit a lot of output),
   `macos-option-as-alt` so Alt chords reach herdr, and a global quake
   terminal on ``cmd+shift+` ``.

### Multiplexer — [herdr](https://herdr.dev/docs)

herdr is a background server that owns real terminals; clients attach and
detach. Panes keep running when you close the laptop or drop the network.

Concept model (see [herdr concepts](https://herdr.dev/docs/concepts/)):

| Concept | Maps to |
|---------|---------|
| **Workspace** | one project (`roblox`, `llm-gnn`, `rl`) |
| **Tab** | a mode inside it (`agents`, `logs`, `gpu`) |
| **Pane** | one process — an agent, a server, `nvitop`, a REPL |
| **Agent** | a detected coding agent; state rolls up to the sidebar |

Config highlights (`herdr/config.toml`):

- **Prefix-free chords** for the Mac (`alt+[`/`]` tabs, `shift+alt+hjkl`
  panes), with `prefix+…` fallbacks that work on the phone. Prefix is
  `ctrl+b`, the classic [tmux](https://github.com/tmux/tmux/wiki) key.
- **`[worktrees]`** — one git worktree per agent under
  `~/.herdr/worktrees`, so parallel agents never edit the same files.
- **`agent_panel_sort = "spaces"`** keeps sidebar rows stable so the
  `shift+alt+1..9` agent-jump keys always land on the same agent.
- **`[ui.toast] delivery = "system"`** notifies even with no client attached.

The **Pi** and **OpenCode** integrations are installed (`herdr integration
install pi|opencode`), which makes herdr a *lifecycle authority* — it gets
real `idle`/`working`/`blocked` events from hooks instead of guessing from
the screen.

### tmux — the long-running exception

herdr panes survive **detach**, but a herdr **server restart** restores
layout and agent conversations — not an arbitrary running process. So a
3-day RL job belongs in tmux underneath a herdr pane:

```bash
mosh runpod -- tmux new -A -s rl          # reattach from the phone
tmux pipe-pane -o 'cat >> ~/.local/state/rl.log'   # leave a trail
```

See [tmux wiki](https://github.com/tmux/tmux/wiki) and
[mosh](https://mosh.org/) for the roaming-friendly transport.

### Zellij

An alternative multiplexer, kept configured (not the primary path). `zj`
attaches to a session named after the current directory. See
[zellij docs](https://zellij.dev/documentation/).

### Editor

Neovim (`$EDITOR=nvim`) — config lives in `~/.config/nvim`, not this repo.
See [Neovim](https://neovim.io/doc/).

### Agent tooling

- **Pi** and **OpenCode** are the coding agents. Both have herdr
  integrations installed; Pi resumes conversations after a herdr restart
  via `pi --session <id>`.
  - OpenCode: <https://opencode.ai/docs>
  - Pi: local docs at `/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/README.md`, or `pi --help`
- **`skills-cli`** installs reusable agent skills from `skills/` into a
  project's `.cursor/`, `.claude/`, or `.codex/` directory:

  ```bash
  skills-cli skills list
  skills-cli skills install ship          # commit, push, open a PR
  skills-cli skills install --all
  ```

  Skills are plain markdown, so they work across agents.

---

## Toolchain by project

The env is shared; the per-project toolchain is not. Relevant docs:

| Project | Tools | Docs |
|---------|-------|------|
| **Roblox game** | Rojo (live sync), Wally (packages), StyLua, Selene, luau-lsp | [Rojo](https://rojo.space/) · [Wally](https://wally.run/) · [StyLua](https://github.com/JohnnyMorganz/StyLua) · [Selene](https://github.com/Kampfkarren/selene) · [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) · [Roblox docs](https://create.roblox.com/docs) |
| **LLM + GNN** | `uv`, ruff, pytest, DuckDB (parquet), NebulaGraph | [uv](https://docs.astral.sh/uv/) · [ruff](https://docs.astral.sh/ruff/) · [DuckDB](https://duckdb.org/docs/) · [NebulaGraph](https://docs.nebula-graph.io/) |
| **RL / fine-tuning** | `uv`, accelerate/TRL, wandb, HF Hub, nvitop | [Hugging Face](https://huggingface.co/docs) · [TRL](https://huggingface.co/docs/trl) · [nvitop](https://github.com/XuehaiPan/nvitop) · [RunPod](https://docs.runpod.io/) · [Hetzner](https://docs.hetzner.com/) |

Python tools are installed once with `uv tool install <name>` and are then
available on every machine.

---

## Daily workflow

```bash
herdr                          # attach (or: herdr --remote hetzner)
# per project a workspace already exists with agents restored
prefix+o                       # jump to whatever agent is blocked/done
prefix+. / prefix+,            # hop between agents
prefix+e                       # open a pane's scrollback in $EDITOR
prefix+shift+g                 # lazygit — review + merge agent worktrees
prefix+y                       # yazi — see what changed
```

From the phone, steer by name rather than fighting a TUI:

```bash
herdr agent list --json | jq -r '.result.agents[]|[.state,.name]|@tsv'
herdr agent read reviewer --lines 80
herdr agent send-keys reviewer -- "yes, rerun the tests" Enter
```

---

## Working across machines

| Client | Transport | Multiplexer | Prompt |
|--------|-----------|-------------|--------|
| Mac + Ghostty | local | herdr (local) | `starship.toml` |
| iPhone + Termius | mosh/ssh + Tailscale | herdr over ssh | `starship.mobile.toml` |
| Hetzner / RunPod | ssh | herdr + tmux | `starship.mobile.toml` |

Register remote servers once, then view them in one herdr window:

```bash
herdr machine add hetzner --label " Hetzner"
herdr machine add runpod  --label " RunPod" --remote-session rl
herdr --remote hetzner          # thin local client for a remote session
```

On a phone, `ssh you@server` then `herdr` opens the same persistent
session; the TUI adapts to narrow screens. [Tailscale](https://tailscale.com/kb/)
removes port-forwarding entirely — SSH to the tailnet name.

---

## Secrets & per-host overrides

Nothing secret is committed. Three escape hatches, all git-ignored:

| File | Use |
|------|-----|
| `~/.config/localenvs/*.local` | API keys, tokens (sourced automatically) |
| `~/.env` | ad-hoc env vars |
| `~/.zshrc.local` | non-secret, host-specific shell tweaks |

```bash
mkdir -p ~/.config/localenvs
echo 'export HF_TOKEN="hf_xxx"' > ~/.config/localenvs/huggingface.local
```

The installer also supports `SKIP_BREW=1` for servers where you don't want
the full package set.

---

## Learn more

Tools and topics used here, grouped. Start with the ones you haven't met.

**Terminal & multiplexing**
- Ghostty — <https://ghostty.org/docs> · [config reference](https://ghostty.org/docs/config/reference)
- herdr — <https://herdr.dev/docs> · [concepts](https://herdr.dev/docs/concepts/) · [agent automation](https://herdr.dev/docs/agent-automation/)
- tmux — <https://github.com/tmux/tmux/wiki> · [cheat sheet](https://tmuxcheatsheet.com/)
- zellij — <https://zellij.dev/documentation/>
- mosh — <https://mosh.org/>
- Kitty keyboard protocol — <https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
- Nerd Fonts — <https://www.nerdfonts.com/> · [PUA (why tofu)](https://en.wikipedia.org/wiki/Private_Use_Areas)

**Shell & prompt**
- zsh — <https://zsh.sourceforge.io/Doc/>
- Starship — <https://starship.rs/guide/> · [config](https://starship.rs/config/)
- zsh-autosuggestions — <https://github.com/zsh-users/zsh-autosuggestions>
- zsh-syntax-highlighting — <https://github.com/zsh-users/zsh-syntax-highlighting>
- fzf-tab — <https://github.com/Aloxaf/fzf-tab>

**Search & navigation**
- fzf — <https://github.com/junegunn/fzf>
- fd — <https://github.com/sharkdp/fd>
- ripgrep — <https://github.com/BurntSushi/ripgrep> · [guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- bat — <https://github.com/sharkdp/bat>
- eza — <https://github.com/eza-community/eza>
- zoxide — <https://github.com/ajeetdsouza/zoxide>
- yazi — <https://yazi-rs.github.io/docs/quick-start>

**Git**
- lazygit — <https://github.com/jesseduffield/lazygit>
- delta — <https://dandavison.github.io/delta/>
- difftastic — <https://difftastic.wilfred.me.uk/>
- git-absorb — <https://github.com/tummychow/git-absorb>

**Runtimes & task running**
- uv — <https://docs.astral.sh/uv/>
- mise — <https://mise.jdx.dev/>
- direnv — <https://direnv.net/>
- just — <https://just.systems/man/en/>
- atuin — <https://atuin.sh/docs>

**Monitoring & data**
- duckdb — <https://duckdb.org/docs/>
- nvitop — <https://github.com/XuehaiPan/nvitop>
- bottom — <https://github.com/ClementTsang/bottom>
- dust — <https://github.com/bootandy/dust>
- procs — <https://github.com/dalance/procs>
- hyperfine — <https://github.com/sharkdp/hyperfine>
- watchexec — <https://github.com/watchexec/watchexec>

**Packaging & dotfiles**
- Homebrew Bundle — <https://docs.brew.sh/Brewfile>
- chezmoi (alternative to this hand-rolled installer) — <https://www.chezmoi.io/>
- Tailscale — <https://tailscale.com/kb/>

**Roblox**
- Roblox creator docs — <https://create.roblox.com/docs>
- Rojo — <https://rojo.space/> · Wally — <https://wally.run/>
- rokit (toolchain manager) — <https://github.com/rojo-rbx/rokit>
- StyLua — <https://github.com/JohnnyMorganz/StyLua> · Selene — <https://github.com/Kampfkarren/selene>
- luau-lsp — <https://github.com/JohnnyMorganz/luau-lsp>

**LLM / GNN / RL**
- Hugging Face — <https://huggingface.co/docs> · TRL — <https://huggingface.co/docs/trl>
- NebulaGraph — <https://docs.nebula-graph.io/>
- RunPod — <https://docs.runpod.io/> · Hetzner — <https://docs.hetzner.com/>

---

## Gotchas

- **Ghostty reads two config paths on macOS.** A file at
  `~/Library/Application Support/com.mitchellh.ghostty/config` silently
  overrides `~/.config/ghostty/config`. `install.sh` moves it aside; if
  fonts/theme ever look wrong, check
  `ghostty +show-config | grep -E 'font-family|theme'`.
- **Ghostty keybinds use a literal `\\x1b`** (two backslashes) in
  `ghostty/config`. It's preserved verbatim from the working setup — verify
  before changing it.
- **Don't keep git repos in iCloud Drive.** iCloud can rewrite
  `.git/objects` mid-operation and corrupt a repo. Code lives in `~/git/`;
  iCloud is for notes.
- **`copy-on-select = false`** is deliberate: it's broken on macOS 26 in
  Ghostty 1.3.x. Use `Cmd-C` (see the comment in `ghostty/config`).
- **Two prompts to keep in sync.** Adding a module to `starship.toml`?
  Add it to `starship.mobile.toml` too, or the phone prompt drifts.
- **herdr server restart ≠ process survival.** Interactive agents resume;
  long jobs need tmux.
- **The `~/Documents/leo*` tree is a live Hermes runtime** bind-mounted by
  `leo/docker-compose.yaml` (`/opt/data`, `/workspace/projects`). Don't
  move or rename it.
