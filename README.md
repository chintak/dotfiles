# dotfiles

One repo for the whole terminal development environment — shell, prompt,
terminal, multiplexer, and agent tooling — on macOS, iOS-over-SSH, and
remote GPU boxes (Hetzner / RunPod). Each config is a small, **versioned
package**; the `dot` CLI installs the ones a machine needs and links them
into place from an immutable store.

This README assumes you don't already know these tools. Each one gets a
short **what / why / how** and a link to learn more. Read the
[Philosophy](#philosophy) and [Bootstrap](#bootstrap-a-new-machine)
sections, then use [The toolbox](#the-toolbox) as a reference.

## Contents

- [Philosophy](#philosophy)
- [Bootstrap a new machine](#bootstrap-a-new-machine)
- [Profiles](#profiles)
- [Repo layout](#repo-layout)
- [The store, symlinks & the lockfile](#the-store-symlinks--the-lockfile)
- [Config package format](#config-package-format)
- [Ephemeral / VM mode](#ephemeral--vm-mode)
- [The config lifecycle](#the-config-lifecycle)
- [The CLI](#the-cli)
- [How the layers fit together](#how-the-layers-fit-together)
- [The toolbox](#the-toolbox)
- [Toolchain by project](#toolchain-by-project)
- [Daily workflow](#daily-workflow)
- [Working across machines](#working-across-machines)
- [Secrets & per-host overrides](#secrets--per-host-overrides)
- [Gotchas](#gotchas)

---

## Philosophy

Three rules hold the whole thing together:

1. **One multiplexer layer.** [herdr](https://herdr.dev/docs) owns panes,
   tabs, and workspaces *everywhere* — Mac, phone, VPS. Ghostty and
   Termius are just fast renderers. Never stack Ghostty splits + herdr
   panes + tmux; pick one. The exception is an unsupervised multi-day job,
   which runs in tmux *underneath* a herdr pane.

2. **Store + symlink, never hand-copies.** `dot` stages each config into
   an immutable, versioned store and symlinks the target at that copy.
   Edit the repo → commit → `dot update`, and every machine re-links.

3. **One theme.** [TokyoNight](https://github.com/tokyo-night/tokyo-night-vscode-theme) across Ghostty and
   Starship, so the terminal looks coherent. (herdr, yazi, and tmux still use Dracula.)
   **One exception:** helix uses `onelight` — a light theme reads better for
   long markdown prose, which is hx's main job here. Deliberate divergence,
   not drift.

The goal is an environment that is **low-latency, glyph-safe, and
identical on every client** — including a 43-column iPhone screen on a
flaky cellular link.

---

## Bootstrap a new machine

One command installs the `dot` CLI and sets up a machine. It needs only
`bash`, `curl`, `git`, and `jq`:

```bash
# whole machine in one shot (macOS profile)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
  -- init --profile mac

# minimal headless server
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
  -- init --profile server

# install the CLI only, then poke around
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" -- --help
```

`bootstrap.sh` downloads `dot` into `~/.local/bin`, warns if that directory
isn't on `PATH`, then `exec`s `dot` with whatever arguments you passed.
Re-running is always safe: `dot` backs up any file it replaces as
`<target>.bak.<timestamp>`, and every step is idempotent.

Environment overrides:

| Variable | Default | Meaning |
|----------|---------|---------|
| `DOT_REPO_URL` | `https://github.com/chintak/dotfiles` | Where to fetch `dot` from |
| `DOT_REF` | `master` | Branch, tag, or SHA to pin to |
| `DOT_BIN_DIR` | `~/.local/bin` | Where `dot` is installed |
| `DOT_REPO` | `~/.local/share/dot/repo` | Repo clone location |
| `DOT_STORE` | `~/.local/share/dot/store` | Versioned store location |
| `DOT_STATE` | `~/.local/state/dot` | Lockfile location |

Pin for reproducibility with `--ref v1.0.0` or `--ref <sha>`. Once installed,
`dot` manages itself: `dot update` pulls the repo and re-applies newer
configs, and `dot purge` removes the repo, store, lockfile, and the CLI.

---

## Profiles

A profile is a plain list of config names in `profiles/<name>.conf`. It is
the answer to "don't install everything everywhere":

```
# profiles/mac.conf          # profiles/server.conf
zsh                          zsh
starship                     starship
ghostty                      herdr
herdr                        tmux
tmux                         git
git                          helix
helix                        yazi
yazi                         glow
glow                         uv-tools
brewfile
uv-tools
opencode
```

`dot init --profile mac` installs them in order, expanding each config's
`requires` first and skipping any whose `platform` doesn't match this host
(so `brewfile` — macOS casks — never lands on a headless box).

There is deliberately **no `ios` profile**: the phone (Termius) doesn't run
`dot`; it SSHes into a host that already has a profile. The glyph-free
mobile prompt is selected at runtime by `zshrc` from `$SSH_CONNECTION`.

---

## Repo layout

```
dotfiles/
├── dot                  # the CLI (bash)
├── bootstrap.sh         # curl entrypoint
├── README.md
├── profiles/            # mac.conf, server.conf, …
└── configs/<tool>/      # one folder per config: README.md, manifest, files/
```

Design decisions and a recreation prompt live outside the repo in
`~/vault/projects/dot-cli.md`.
```

Each `configs/<tool>/` is a package:

| File | What it is |
|------|------------|
| `manifest` | version, description, platform, `file` mappings, optional `requires` / `post_apply` |
| `files/` | what gets installed, paths relative to here |
| `README.md` | why this tool is configured the way it is |

> The repo lives under `~/.local/share/dot/repo` when `dot` clones it (not
> `~/Documents/…`) because code and dotfiles belong outside iCloud Drive —
> see [Gotchas](#gotchas). A dev checkout in `~/git/dotfiles` is also
> detected and used directly.

---

## The store, symlinks & the lockfile

`dot` never edits a config in place and never copies one blindly. Applying
a config means:

1. Stage the config's `files/` into an immutable, versioned store:
   `~/.local/share/dot/store/<config>/<version>/`.
2. Symlink each target at the store copy, backing up anything already
   there.
3. Record what happened in a JSON lockfile at
   `~/.local/state/dot/installed.json`.

```
target  ~/.config/ghostty/config ──▶ store/ghostty/1.0.0/config
```

Because the target is a symlink into a real, versioned file, old versions
stay around: `dot rollback ghostty 0.9.0` just re-points the symlink, and
`dot status` can tell you exactly what drifted. Every installed version is
retained in v1 (garbage collection is deferred).

The lockfile is the record of what this machine has — which is what makes
`status`, `update`, `rollback`, and `doctor` possible:

```json
{
  "lockfileVersion": 1,
  "configs": {
    "ghostty": {
      "version": "1.0.0",
      "mode": "symlink",
      "hash": "sha256:a1b2c3…",
      "store": "~/.local/share/dot/store/ghostty/1.0.0",
      "targets": ["~/.config/ghostty/config"],
      "installedAt": "2026-09-21T13:52:00Z"
    }
  }
}
```

**Drift detection, not prevention.** There is no `chmod 444` in v1 — a tool
that rewrites its own config isn't broken, it's just drifted. `dot status`
compares target content and the repo version against the lockfile and
reports `ok` / `stale` / `modified` / `drifted` / `broken` / `unmet` /
`inapplicable`; `--exit-code` makes it usable in a prompt. `dot doctor`
checks the machinery (git/jq/curl present, repo healthy, store writable,
manifests valid) and `--fix` repairs what it safely can.

---

## Config package format

`configs/ghostty/manifest` is plain `key = value`, one per line — no parser:

```
version     = 1.0.0
description = Ghostty — fast renderer; hands its chords to herdr
platform    = mac
requires    = zsh
file        = config|~/.config/ghostty/config
# post_apply = brew bundle --file ~/.config/dot/Brewfile
```

| Key | Required | Meaning |
|-----|----------|---------|
| `version` | yes | semver of this config |
| `description` | yes | one line, shown by `dot list` / `dot info` |
| `file` | yes (≥1, unless `post_apply`) | `src-rel-path\|target` — repeatable; `src` is relative to `files/` |
| `requires` | no | comma-separated config names applied first |
| `platform` | no | `mac` / `linux` / `any` (default `any`) |
| `post_apply` | no | one command run after the config is (re)installed |

Targets support `~` and `${VAR}` expansion. `post_apply` is deliberately the
only hook: it exists so configs whose job is an *action* rather than a file
(package installation) fit the model. It runs whenever the config's
`applyHash` — version + file contents + the `post_apply` string — changes,
so adding a tool to `uv-tools.txt` re-runs it while re-applying an
unchanged config does not.

**Why flat.** `configs/<tool>/` *is* the config; the atomic unit of `dot` is
a config, so the directory mirrors that. A `configs/shell/starship/`
hierarchy would imply nesting the install model doesn't have, and ambiguous
cases (Is Starship a shell thing or a prompt thing?) stop being structural
questions. There are no categories — `dot list` is one flat, alphabetical
table.

Adding a config:

```bash
mkdir -p configs/<name>/files
# write configs/<name>/manifest, README.md, and files/…
dot list                       # it should appear
dot apply <name> --dry-run
dot apply <name>
dot bump <name> minor
```

---

## Ephemeral / VM mode

For VM images, CI runners, and one-shot containers where updates are not a
concern, `--ephemeral` installs real files and then deletes all the tooling:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/chintak/dotfiles/master/bootstrap.sh)" \
  -- init --profile server --ephemeral
```

It shallow-clones the repo, applies configs in **copy** mode (plain files at
the targets — no store, no symlinks), optionally writes a reference
lockfile, then purges the clone, the store, `~/.local/bin/dot`, and the
state directory. The result is a lean image with working config files and
zero tooling — and deliberately no future update path. The purge is refused
unless `--ephemeral` was passed *and* every install succeeded.

---

## The config lifecycle

The store is versioned, so there is a real edit loop:

```bash
dot edit ghostty          # opens the repo file in $EDITOR
# …make changes…
dot bump ghostty minor    # bump semver, commit with a conventional message
dot update                # git pull --rebase --autostash, then re-apply
```

`dot bump <config> major|minor|patch` follows a convention so versions mean
something:

| Bump | When |
|------|------|
| **major** | Breaking: target path moves, an option is renamed/removed, a newer tool version is required |
| **minor** | Backward-compatible: new option, new binding, new file in the package |
| **patch** | Comments, formatting, typo |

`dot update` pulls with `git pull --rebase --autostash` (opt out with
`--no-pull`) and re-links configs whose repo version is newer. To adopt an
existing hand-edited file, `dot add <path>` copies it into the repo, creates
or patches a manifest, and replaces the target with a symlink into the
store.

---

## The CLI

Verbs follow `chezmoi` where an equivalent exists, plus the versioning layer
chezmoi lacks.

| Command | Does |
|---------|------|
| `dot init [--profile P] [--repo URL] [--ref R] [--ephemeral]` | Clone repo, then apply |
| `dot apply [<config>…] [--profile P] [--dry-run] [--lock]` | Install / reinstall |
| `dot forget <config>…` | Remove symlinks + lockfile entries (store kept) |
| `dot update [<config>…] [--no-pull] [--dry-run]` | Pull, then apply newer versions |
| `dot rollback <config> [version]` | Re-point symlinks at an older store version |
| `dot gc [--dry-run]` | Prune superseded store versions (stores of uninstalled configs are kept) |
| `dot purge [--yes]` | Delete repo, store, lockfile, and the CLI |
| `dot add <path>` | Adopt a file: copy into repo, replace target with a link |
| `dot edit <config>` | Open the repo file in `$EDITOR` |
| `dot diff <config>` | Repo vs installed |
| `dot status [--exit-code] [--json]` | What `apply` would change (content drift) |
| `dot doctor [--fix]` | Environment + tooling health; `--fix` repairs what it can |
| `dot cd` | Shell into the repo clone |
| `dot list [--installed\|--available] [--json]` | Discover configs |
| `dot info <config>` | Files, targets, requires, version, state |
| `dot profiles` | List profiles and their configs |
| `dot bump <config> major\|minor\|patch` | Bump version, commit |

```
$ dot status
config     installed  available  state
ghostty    1.0.0      1.0.0      ok
zsh        1.4.1      1.5.0      stale
starship   1.0.0      1.0.0      modified
herdr      —          0.9.0      not installed
```

Design history: the full design was distilled into
`~/vault/projects/dot-cli.md` (recreation prompt).

---

## How the layers fit together

Four pieces, each doing one job:

```
Ghostty (Mac)  ─┐
                ├─→  herdr  ──→  agents (pi / opencode), servers, tests
Termius (iOS)  ─┘      │
                       └─→  remote machines (Hetzner, RunPod) in one sidebar
```

- **Ghostty/Termius** render. They hold no state.
- **herdr** owns the terminals. It runs as a background server, so panes
  survive closing the laptop or dropping the network.
- **zsh + Starship** are what you type into. `zshrc` picks the prompt
  based on whether you're on SSH.
- **`~/git/`** is where code lives.

Three wiring details that aren't obvious:

1. **Prompt switching.** `zshrc` sets `STARSHIP_CONFIG` to the mobile
   profile when `$SSH_CONNECTION`/`$SSH_TTY` is set, so the phone gets a
   glyph-free prompt and the Mac gets the powerline one — from one config
   file.
2. **Chord handoff.** Ghostty's own split/tab shortcuts are freed so herdr
   receives them. This is the fiddliest part of the setup; the comments in
   `ghostty/config` explain it.
3. **Agent awareness.** The Pi and OpenCode herdr integrations are
   installed, so herdr gets real `working`/`blocked`/`done` events from
   agent hooks instead of guessing from the screen.

---

## The toolbox

What's installed and why. **What** it is, **why** it earns a place here,
and **how** to use it. Start with the ones marked ⭐ if you're new.

### Terminal & multiplexing

**⭐ `Ghostty`** — a fast, GPU-accelerated terminal emulator
([docs](https://ghostty.org/docs)). It renders heavy agent output without
dropping frames and restores your tabs/splits on relaunch. Here it's the
*renderer only* — it hands its chords to herdr. Inspect the live config
with `ghostty +show-config | grep -E 'font-family|theme'`.

**⭐ `herdr`** — a terminal multiplexer built for coding agents
([docs](https://herdr.dev/docs) · [concepts](https://herdr.dev/docs/concepts/)).
Unlike tmux, it's agent-aware: it detects Pi/OpenCode in a pane and shows
each one's state in a sidebar, so you can see across projects which agent
is `blocked`. It runs as a background server, so you detach (`ctrl+b q`)
and reattach (`herdr`) from any machine. Use it for *everything*
interactive.

**`tmux`** — the classic terminal multiplexer
([wiki](https://github.com/tmux/tmux/wiki) · [cheat sheet](https://tmuxcheatsheet.com/)).
Included only for unsupervised long jobs that must survive a **herdr
server restart** (herdr restores layout and agent conversations, not an
arbitrary running process). `tmux new -s rl`, then `ctrl+b d` to detach,
`tmux attach -t rl` to return.

**`mosh`** — "mobile shell" ([mosh.org](https://mosh.org/)). Like SSH but
survives roaming and high latency (it does local echo, so typing feels
instant on a phone). `mosh host -- tmux new -A -s main` reattaches to
everything from iOS.

**`Tailscale`** — a WireGuard mesh VPN ([docs](https://tailscale.com/kb/)).
Puts your Mac and GPU boxes on a private network so you can `ssh mac` from
your phone with no port-forwarding or dynamic DNS. `tailscale status`.

**⭐ `Nerd Fonts`** — icon-patched programming fonts
([nerdfonts.com](https://www.nerdfonts.com/)). The icons live in Unicode's
[Private Use Area](https://en.wikipedia.org/wiki/Private_Use_Areas),
which has **no OS font fallback** — if a client's font lacks them you get
tofu boxes (`□□□`). This is why there are two prompts; see
[why PUA has no fallback](https://termai.sh/blog/mobile-terminal-fonts-glyphs).

### Shell & prompt

**`zsh`** — the shell ([manual](https://zsh.sourceforge.io/Doc/)).
Configured entirely by `zshrc`.

**⭐ `Starship`** — a fast, cross-shell prompt written in Rust
([guide](https://starship.rs/guide/) · [config](https://starship.rs/config/)).
One binary, one TOML file, no shell-specific scripting. `starship explain`
shows which prompt modules are active and how slow they are.

**`zsh-autosuggestions`** — greys out a completion from your history as
you type; press `→` to accept ([docs](https://github.com/zsh-users/zsh-autosuggestions)).

**`zsh-syntax-highlighting`** — colors the command line as you type (red =
no such command), catching typos before Enter
([docs](https://github.com/zsh-users/zsh-syntax-highlighting)). Must be
sourced **last**.

**`fzf-tab`** — replaces zsh's plain Tab menu with an fzf picker
([docs](https://github.com/Aloxaf/fzf-tab)).

**`atuin`** — shell history in a SQLite database, searchable with
`Ctrl-R`, and optionally synced across machines
([docs](https://atuin.sh/docs)). `atuin search -i` for a full-screen
search; `atuin stats` for your most-used commands.

**`zoxide`** — a `cd` that learns your habits
([docs](https://github.com/ajeetdsouza/zoxide)). Here `cd` is aliased to
it, so `z proj` jumps to the best-matching directory by frecency, and
plain `cd` still works.

**`direnv`** — loads a `.envrc` when you `cd` into a project and unloads
it when you leave ([docs](https://direnv.net/)). Run `direnv allow` once
per project to trust it. Great for per-project API keys and `PATH` edits.

**`mise`** — installs and switches language runtimes per project
([docs](https://mise.jdx.dev/)). Drop a `.mise.toml` pinning
`python = "3.12"` and it's active only in that directory.

### Search & navigation

**⭐ `fzf`** — a general-purpose fuzzy finder
([docs](https://github.com/junegunn/fzf)). It filters *any* piped list
interactively. Wired up here as `Ctrl-T` (files), `Ctrl-R` (history),
`Alt-C` (directories), and `**<Tab>` (fuzzy completion). Pipe it into
anything: `rg -l TODO | fzf -m`.

**⭐ `fd`** — a friendlier `find` ([docs](https://github.com/sharkdp/fd)).
Faster, colored, and respects `.gitignore` by default, so it never lists
`node_modules`. `fd -e py -x wc -l` runs a command on every match.

**⭐ `ripgrep` (`rg`)** — a faster `grep`
([docs](https://github.com/BurntSushi/ripgrep) · [guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)).
Recursive, respects `.gitignore`, and understands regex + file types.
`rg -l TODO` lists files; `rg --json` feeds structured results to scripts.

**`bat`** — `cat` with syntax highlighting, line numbers, and git change
markers ([docs](https://github.com/sharkdp/bat)). Used as the fzf preview
here. `bat file.py`, or `bat -A` to see invisible characters.

**`eza`** — a modern `ls` ([docs](https://github.com/eza-community/eza)).
Icons, colors, git status, and a real tree mode. `eza -la --git --tree --level=2`.

**`yazi`** — a fast terminal file manager
([docs](https://yazi-rs.github.io/docs/quick-start)). Fully async, and it
previews images, PDFs, and code inline — useful for watching agents mutate
files. Launch with `y`.

### Git

**`lazygit`** — a terminal UI for git
([docs](https://github.com/jesseduffield/lazygit)). Stage individual
hunks, rebase, and resolve conflicts visually instead of memorizing
commands. Here it's how you review and merge agent worktrees.

**`delta`** — a syntax-highlighting diff pager
([docs](https://dandavison.github.io/delta/)). Makes `git diff` readable.
Not wired up yet — enable with
`git config --global core.pager delta` and
`git config --global interactive.diffFilter 'delta --color-only'`.

**`difftastic`** — a *structural* diff that understands syntax
([docs](https://difftastic.wilfred.me.uk/)). Shows what actually changed
semantically instead of line noise — excellent for reviewing an agent's
edits. `git difftool --tool=difftastic`.

**`git-absorb`** — turns your staged changes into `--fixup` commits and
autosquashes them into the right commit
([docs](https://github.com/tummychow/git-absorb)). Keeps history clean
when an agent leaves work on the wrong commit. `git absorb`.

### Runtimes & task running

**⭐ `uv`** — a very fast Python package, project, and tool manager written
in Rust ([docs](https://docs.astral.sh/uv/)). It replaces `pip`, `venv`,
`pipx`, and `pyenv` in one binary. `uv run pytest` runs in the project
env; `uv tool install ruff` installs a CLI globally; `uv sync` installs
from `pyproject.toml` + `uv.lock`.

**`just`** — a command runner ([manual](https://just.systems/man/en/)). A
Makefile without the tab/`.PHONY` pain. Put recipes in a `justfile` and
run `just test`, `just train`. This is the shared entry point you *and*
your agents should call.

**`watchexec`** — reruns a command when files change
([docs](https://github.com/watchexec/watchexec)). `watchexec -e py --
pytest -q` gives you a live test loop while an agent edits.

**`hyperfine`** — benchmarks commands with proper statistics
([docs](https://github.com/sharkdp/hyperfine)). `hyperfine 'cmd-a' 'cmd-b'`
before letting an agent "optimize" anything.

**`duckdb`** — an in-process SQL database for analytics
([docs](https://duckdb.org/docs/)). Query Parquet/CSV/JSON directly with
no server or loading step: `duckdb -c "select count(*) from 'x.parquet'"`.
Ideal for eyeballing datasets and RL rollouts.

### Monitoring & system

**`nvitop`** — an interactive GPU monitor for NVIDIA
([docs](https://github.com/XuehaiPan/nvitop)). Like `nvidia-smi` but live
and navigable. `nvitop -m` in a herdr pane to watch VRAM during training.

**`bottom` (`btm`)** — a graphical system monitor
([docs](https://github.com/ClementTsang/bottom)). CPU, memory, network,
disk, and process tree in one TUI.

**`procs`** — a modern `ps` ([docs](https://github.com/dalance/procs)).
Human-readable, colored, with a tree view. `procs python`.

**`dust`** — `du` that shows the biggest directories as a tree
([docs](https://github.com/bootandy/dust)). `dust -d 2`.

**`duf`** — `df` with a clean table and sorting
([docs](https://github.com/muesli/duf)). `duf`.

### Data & formatting

**`jq`** — the standard JSON processor ([manual](https://jqlang.github.io/jq/manual/)).
`... | jq -r '.result.agents[] | [.state,.name] | @tsv'`. You'll use this
constantly to read herdr's `--json` output.

**`yq`** — the same idea for YAML/TOML/XML
([docs](https://mikefarah.gitbook.io/yq/)). `yq '.a.b' file.yaml`.

**`tealdeer` (`tldr`)** — community examples for man pages, because man
pages are too long ([docs](https://github.com/dbrgn/tealdeer)). `tldr tar`
shows the 5 commands you actually want.

**`glow`** — renders Markdown in the terminal
([docs](https://github.com/charmbracelet/glow)). `glow README.md` — handy
for reading docs and agent output.

**`gum`** — a toolkit for pretty shell scripts: prompts, choices, spinners
([docs](https://github.com/charmbracelet/gum)). Use it when a script needs
to ask you something.

### Packaging & dotfiles

**`Homebrew Bundle`** — a declarative package manifest
([docs](https://docs.brew.sh/Brewfile)). The `Brewfile` lists every tool;
`brew bundle` installs them all, `brew bundle check` reports what's
missing.

**`chezmoi`** — a template-based dotfile manager
([docs](https://www.chezmoi.io/)). The grown-up alternative to this
hand-rolled `dot` if you ever want per-host templating and secrets
management.

**`uv tool`** — how Python CLIs are installed here
([docs](https://docs.astral.sh/uv/guides/tools/)). Isolated environments,
no `sudo`, identical on every machine: `uv tool install <name>`.

### Coding agents

**`Pi`** — a coding agent. Docs ship with the install:
`/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/README.md`,
or `pi --help`. It deliberately has **no MCP** — instead you give it CLI
tools with READMEs ("skills") or extensions.

**`OpenCode`** — an open-source coding agent
([docs](https://opencode.ai/docs)). Supports LSP, formatters, plugins, and
**MCP servers** — so Roblox Studio MCP is wired here, not into Pi. The
`opencode` config versions `opencode.jsonc` (agent settings), `tui.jsonc`
(herdr TUI plugin loader), plus the `agents/` and `skills/` definitions;
runtime state (`cli.json`, `service.json`, `node_modules/`, `plugins/`)
stays out of the store.

### Roblox

**`Rojo`** — syncs a filesystem project into Roblox Studio live
([rojo.space](https://rojo.space/)). You edit `.luau` files in your
editor; Studio updates instantly. `rojo serve` runs the sync;
`rojo sourcemap --watch` generates the `sourcemap.json` that gives your
editor real types.

**`Wally`** — the package manager for Luau
([wally.run](https://wally.run/)). `wally install` pulls dependencies
listed in `wally.toml`.

**`StyLua`** — the Luau formatter ([docs](https://github.com/JohnnyMorganz/StyLua)).
`stylua .` formats the project; `stylua --check .` in CI.

**`Selene`** — the Luau linter ([docs](https://github.com/Kampfkarren/selene)).
`selene .` catches bugs and style issues.

**`luau-lsp`** — the language server for Luau
([docs](https://github.com/JohnnyMorganz/luau-lsp)). Gives your editor and
agents completion, hover types, and go-to-definition, driven by the Rojo
sourcemap.

**`rokit`** — a toolchain manager for Roblox tools
([docs](https://github.com/rojo-rbx/rokit)), the `mise` of the Rojo world.
Pin Rojo/Wally/StyLua versions in `rokit.toml` so every machine and
collaborator agrees.

**`Roblox Studio MCP`** — lets an agent read and modify the live DataModel
in Studio ([Roblox docs](https://create.roblox.com/docs)). Configure it in
OpenCode's `mcp` block; keep Studio open while the agent works.

### LLM / GNN / RL

**`Hugging Face Hub` (`hf`)** — download and upload models and datasets
([docs](https://huggingface.co/docs/huggingface_hub)). `hf download <repo>`,
`hf upload <repo> <path>`.

**`TRL`** — training library for RLHF/DPO/PPO on HF models
([docs](https://huggingface.co/docs/trl)). The usual starting point for
fine-tuning.

**`NebulaGraph`** — a distributed graph database
([docs](https://docs.nebula-graph.io/)). Your GNN feature source; connect
with `nebula-console-login` (alias defined in `zshrc`).

**`RunPod`** — a GPU cloud ([docs](https://docs.runpod.io/)) · **`Hetzner`**
— cheap servers ([docs](https://docs.hetzner.com/)). Register them once
with `herdr machine add` and view them in one sidebar.

**`wandb`** — experiment tracking ([docs](https://docs.wandb.ai/)). Log
loss curves and metrics; run offline on flaky networks and `wandb sync`
later.

### Concepts

**Kitty keyboard protocol** — a terminal protocol for reporting
modifier-heavy keys unambiguously
([spec](https://sw.kovidgoyal.net/kitty/keyboard-protocol/)). Ghostty uses
it to hand `cmd+…` chords to herdr.

**Private Use Area (PUA)** — the Unicode range reserved for private
agreement between a font and software. Nerd Font icons live here, which is
why they have no fallback and show as tofu on phones
([background](https://en.wikipedia.org/wiki/Private_Use_Areas)).

---

## Toolchain by project

The environment is shared; the per-project toolchain is not.

| Project | Tools | Docs |
|---------|-------|------|
| **Roblox game** | Rojo, Wally, StyLua, Selene, luau-lsp, rokit | see [Roblox](#roblox) above |
| **LLM + GNN** | `uv`, ruff, pytest, DuckDB, NebulaGraph | [uv](https://docs.astral.sh/uv/) · [ruff](https://docs.astral.sh/ruff/) · [DuckDB](https://duckdb.org/docs/) · [NebulaGraph](https://docs.nebula-graph.io/) |
| **RL / fine-tuning** | `uv`, TRL, `hf`, wandb, nvitop | see [LLM / GNN / RL](#llm--gnn--rl) above |

---

## Daily workflow

```bash
herdr                          # attach (or: herdr --remote hetzner)
# each project is a workspace; agents are restored automatically
prefix+o                       # jump to whatever agent is blocked/done
prefix+. / prefix+,            # hop between agents
prefix+e                       # open a pane's scrollback in $EDITOR
prefix+shift+g                 # lazygit — review + merge agent worktrees
prefix+y                       # yazi — see what changed
```

From the phone, steer by name instead of fighting a TUI:

```bash
herdr agent list --json | jq -r '.result.agents[]|[.state,.name]|@tsv'
herdr agent read reviewer --lines 80
herdr agent send-keys reviewer -- "yes, rerun the tests" Enter
```

---

## Working across machines

| Client | Transport | Multiplexer | Prompt |
|--------|-----------|-------------|--------|
| Mac + Ghostty | local | herdr | `starship.toml` |
| iPhone + Termius | mosh/ssh + Tailscale | herdr over ssh | `starship.mobile.toml` |
| Hetzner / RunPod | ssh | herdr + tmux | `starship.mobile.toml` |

Register remote servers once, then view them all in one herdr window:

```bash
herdr machine add hetzner --label " Hetzner"
herdr machine add runpod  --label " RunPod" --remote-session rl
herdr --remote hetzner          # thin local client for a remote session
```

On a phone, `ssh you@server` then `herdr` opens the same persistent
session; the TUI adapts to narrow screens.

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

---

## Gotchas

- **Ghostty reads two config paths on macOS.** A file at
  `~/Library/Application Support/com.mitchellh.ghostty/config` silently
  overrides `~/.config/ghostty/config`. If fonts/theme look wrong, move
  that file aside and run
  `ghostty +show-config | grep -E 'font-family|theme'`.
- **Ghostty keybinds use a literal `\\x1b`** (two backslashes) in
  `ghostty/config`. Preserved verbatim from the working setup — verify
  before changing it.
- **Don't keep git repos in iCloud Drive.** iCloud can rewrite
  `.git/objects` mid-operation and corrupt a repo. Code lives in `~/git/`;
  iCloud is for notes.
- **`copy-on-select = false`** is deliberate: it's broken on macOS 26 in
  Ghostty 1.3.x. Use `Cmd-C`.
- **Two prompts to keep in sync.** Adding a module to `starship.toml`? Add
  it to `starship.mobile.toml` too, or the phone prompt drifts.
- **herdr server restart ≠ process survival.** Interactive agents resume;
  long jobs need tmux.
- **The `~/Documents/leo*` tree is a live Hermes runtime** bind-mounted by
  `leo/docker-compose.yaml` (`/opt/data`, `/workspace/projects`). Don't
  move or rename it.
