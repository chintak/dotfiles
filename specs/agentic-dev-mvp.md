# Spec: Agentic Dev MVP — `dot` runtime + Herdr tab-per-task workflow

- **Status:** final (rev 1)
- **Owner:** Chintak
- **Date:** 2026-09-22
- **Companion spec:** `specs/dot-cli.md` (authoritative for the config *lifecycle*: store, lockfile, semver, profiles)
- **This spec:** authoritative for the *runtime* workflow — toolchain config packages, git wiring, Herdr layout/naming, the `dot.worktree` plugin, the `herdr-subagents` Pi skill, and transcripts.
- **Execution:** not started. This document is the build contract.

---

## 0. Decisions (read this first)

| # | Decision | Rationale |
|---|----------|-----------|
| **R1** | `dot` stays the config-lifecycle CLI from `dot-cli.md`, and **gains a second verb family** (`up`, `task`, `review`, `web`, `transcript`, `name`) for the runtime workflow. One binary. | "the dot cli" — one tool, one PATH entry. Config verbs manage the machine; runtime verbs manage the work. |
| **R2** | A worktree is represented as **tabs + panes inside one project workspace**, *not* as a Herdr worktree-workspace. We therefore **do not** use `herdr worktree create/open/remove`. | Herdr's native worktree feature creates *linked worktree workspaces* ("workspace groups"). The requested layout is "one workspace per project". These are mutually exclusive. See §9. |
| **R3** | Subagents get a **new tab**, never a sibling pane. | Explicit user requirement; deliberate override of `herdr --skill`'s "default to a sibling pane" guidance. |
| **R4** | Name branches, worktrees, tabs, panes, and agents with `"<commit-type>-<2..3-word-slug>"`, hyphen-separated, **≤ 32 chars**. | Herdr agent names must match `[a-z][a-z0-9_-]{0,31}`. One canonical id reused everywhere. §10. |
| **R5** | Git diff wiring lives in the **XDG global file** `~/.config/git/config`, leaving `~/.gitconfig` (user identity) untouched. | Git reads both; `~/.gitconfig` wins conflicts and only holds `user.*`. No clobbering, no include plumbing. |
| **R6** | `delta` is the default git pager; `difftastic` is **opt-in** via aliases/`difftool`. Never set `diff.external` globally. | `diff.external` breaks tooling and interactive `git add -p`. §6. |
| **R7** | Review tab = one pane per **dirty** worktree; Web tab = one pane per task's dev server; Agent tab = one per task. | Requested layout. Panes are reconciled on `dot up` and on each task change. §9. |
| **R8** | Repo-local config is a flat `key = value` `.dotdev` file, parsed in bash. No TOML parser dependency. | Honors `dot-cli.md` G8 (bash + `git` + `jq` only). §8. |
| **R9** | Transcript HTML is rendered by a `jq` program (`@html`), no Node dependency. | Keeps the bash-only constraint; `pi`'s `/tree`, `/export`, `/share` are surfaced, not reimplemented. §12. |

---

## 1. Goals

| # | Goal |
|---|------|
| G1 | One command brings the whole environment up on a machine (via `dot init --profile mac`). |
| G2 | Rendered markdown, file browsing, LSP, HTML preview, images/PDFs, and diffs all work from inside Herdr panes. |
| G3 | Creating a task is one command: it makes the branch + worktree, opens an agent tab, adds a review pane and a dev-server pane, and names everything consistently. |
| G4 | A running Pi agent can spawn **subagent tabs** (each with its own worktree) and collect their results via the Herdr CLI. |
| G5 | Any agent's full session (including tool calls) can be reviewed as HTML and analyzed for cost/tool-call patterns. |
| G6 | Everything ships as `dot` config packages with profiles, so it is installable on a Mac and on a headless server. |

### Non-goals
- Windows.
- Replacing Herdr's own worktree workspaces (we deliberately diverge; see R2).
- A TUI of our own for tasks — Herdr *is* the UI.
- Templating or host conditionals in configs (per `dot-cli.md`).

---

## 2. Architecture

```
                       ┌────────────────────────────────────────────────┐
   dot init --profile  │  dot (bash)                                    │
   mac|server     ───▶ │   config verbs: init apply status doctor …     │
                       │   runtime verbs: up task review web transcript │
                       └───────┬───────────────────────┬────────────────┘
                               │                       │
              installs config  │                       │  drives
              packages         ▼                       ▼
   ~/.config/{git,helix,yazi,herdr,glow}/…      ┌──────────────┐
   ~/.config/herdr/plugins/dot.worktree/         │   Herdr      │  workspaces / tabs / panes / agents
   ~/.pi/agent/skills/herdr-subagents/           │  (server)    │  socket API + CLI
                                                 └──────┬───────┘
                                                        │ holds real terminals
                              ┌─────────────────────────┼─────────────────────────┐
                              ▼                         ▼                         ▼
                        agent tabs                 review tab                 web tab
                   (one per task, one          (one pane per dirty        (one pane per task,
                    worktree each)              worktree)                  dev server each)
```

Three layers, three responsibilities:

1. **`dot`** — lifecycle + orchestration. Owns naming, git, layout reconciliation, transcripts.
2. **`dot.worktree`** (Herdr plugin) — the Herdr-facing surface: actions, a task board, link handlers. Thin; calls `dot`.
3. **`herdr-subagents`** (Pi skill) — teaches a Pi agent to delegate via new tabs.

---

## 3. The `dot` CLI — MVP scope

Full lifecycle is specified in `dot-cli.md`. The MVP implements the subset needed to deliver this environment, plus the new runtime verbs.

### 3.1 Config verbs (from `dot-cli.md`, MVP subset)

`init`, `apply`, `list`, `info`, `status`, `doctor`, `update`, `edit`, `diff`, `profiles`, `cd`

Deferred to a later phase: `add`, `bump`, `rollback`, `forget`, `purge`, `--ephemeral`, `--lock`, `parts/`.

### 3.2 Runtime verbs (new, this spec)

| Command | Does |
|---|---|
| `dot up` | Ensure the project workspace exists and reconcile the `review` and `web` tabs + panes. Idempotent. Run after opening a project. |
| `dot name <type> <word>…` | Print the canonical task id (`. §10`). Used by the plugin, the skill, and humans. |
| `dot task new <type> <word>… [--prompt TEXT] [--base REF] [--kind pi\|opencode] [--no-agent]` | Branch + worktree + agent tab + review pane + web pane. §9.3. |
| `dot task list [--json] [--watch]` | Task table (task, branch, worktree, agent state, dirty?, dev url). Backs the plugin board. |
| `dot task open <task>` | Focus the task's agent tab (`herdr tab focus`). |
| `dot task finish <task> [--merge\|--pr\|--keep]` | Stop dev, close tab + panes, remove worktree, optionally merge/PR. §9.4. |
| `dot review <task> [--difft] [--staged] [--watch]` | Render the worktree diff (delta by default; `--difft` for structural). |
| `dot web <task>` / `dot web open <task>` / `dot web restart <task>` | Show URL / open in browser / re-run the dev command in its pane. |
| `dot transcript <task\|--session ID\|--current> <path\|render\|open\|share\|stats\|focus>` | Pi session surface. §12. |

**Config vs runtime split.** Config verbs read/write the store, lockfile, and `~/.config/*`. Runtime verbs never touch the store — they talk to Herdr over its socket and to git in worktrees. `dot status`/`dot doctor` never invoke Herdr; `dot up`/`dot task` never mutate dotfiles. This keeps the two halves independently testable.

**Dependencies.** `git`, `jq`, `bash` (as `dot-cli.md`). Runtime verbs additionally require a running Herdr server and `herdr` on `PATH`. `yq` is *not* required (R8).

---

## 4. Config packages to add

All follow the `configs/<tool>/{README.md,manifest,files/}` format from `dot-cli.md` §7.

| Config | `category` | Platforms | Target(s) | Notes |
|---|---|---|---|---|
| `git` | `vcs` | any | `~/.config/git/config` | delta + difftastic wiring. §6. |
| `helix` | `editor` | any | `~/.config/helix/config.toml`, `languages.toml` | LSP + file browsing. §5. |
| `yazi` | `terminal` | any | `~/.config/yazi/{yazi,keymap,theme}.toml` | Files + images/PDF previews + openers. §5. |
| `glow` | `agents` | any | `~/.config/glow/glow.yml` | Rendered markdown. §5. |
| `herdr` | `multiplexer` | any | `~/.config/herdr/config.toml` | Already exists. Add `post_apply` to install integrations. |
| `herdr-plugin-dot-worktree` | `agents` | any | `~/.config/herdr/plugins/dot.worktree/` (via `post_apply`) | §11. |
| `pi-skill-herdr-subagents` | `agents` | any | `~/.pi/agent/skills/herdr-subagents/` | §11. |
| `brewfile` | `packages` | mac | `~/.config/dot/Brewfile` | Add `helix`, `poppler`, `chafa`. Others already present. |
| `uv-tools` | `packages` | any | `~/.config/dot/uv-tools.txt` | unchanged |

`configs/herdr/manifest` gains:

```
post_apply = herdr integration install pi && herdr integration install opencode && herdr server reload-config
```

`configs/herdr-plugin-dot-worktree/manifest`:

```
version     = 0.1.0
description = Herdr plugin: tab-per-task worktree workflow
category    = agents
requires    = herdr
post_apply  = herdr plugin link ~/.config/dot/plugins/dot.worktree && herdr plugin enable dot.worktree
```

> `herdr plugin link` takes a local path; the plugin source is staged into `~/.config/dot/plugins/dot.worktree` by the config package, then linked. `herdr plugin list` is the verification.

---

## 5. Toolchain wiring

### 5.1 Markdown — glow

- `configs/glow/files/glow.yml` → `~/.config/glow/glow.yml` (style, width, pager).
- Zsh: `alias md='glow -p'` and a `mdp()` helper that pipes the last agent output file to `glow`.
- In Herdr: `herdr pane run <review-or-agent-pane> "glow <file>"`, or `$PAGER=glow` for `.md` only.
- Verification: `glow README.md` renders headings, tables, code, and images.

> Key names in `glow.yml` (e.g. `style`, `width`, `pager`) to be confirmed against `glow --help` at build time; if they differ, the file is documentation + env-only.

### 5.2 Files + images/PDF — yazi

`configs/yazi/files/yazi.toml`:

```toml
[opener]
edit = [{ run = 'hx "$@"', block = true }]
text = [{ run = 'hx "$@"', block = true }]
markdown = [{ run = 'glow "$@"', block = true }]
pdf = [{ run = 'open "$@"', orphan = true }]     # macOS; Linux profile → zathura
image = [{ run = 'open "$@"', orphan = true }]
```

- Built-in previewer renders images and PDFs inline (PDFs need `poppler`'s `pdftoppm`; added to the Brewfile).
- `keymap.toml`: `<Enter>` → `open`, `e` → `open --hovered` with the `edit` opener (Helix), `y` yank path.
- `~/.config/yazi` currently has no contents; `dot apply git` will create it via symlink into the store.
- The terminal must expose a graphics protocol — Ghostty does (`kitty_graphics = true` is already set in `herdr/config.toml`). `chafa` is the fallback for non-graphics terminals.

### 5.3 LSP + code browsing — Helix

- `configs/helix/files/config.toml`:
  ```toml
  theme = "base16_transparent"
  [editor]
  line-number = "relative"
  bufferline = "multiple"
  [editor.lsp]
  display-inlay-hints = true
  ```
- `languages.toml` pins servers per language only where auto-detect is insufficient.
- Helix auto-detects and starts LSP servers found on `PATH` — no plugin manager, no `nvim-lspconfig`.
- `$EDITOR=hx`, `$VISUAL=hx` (set in `zshrc`). Git `core.editor = hx` (in the git config package).
- "Code browsing" = run `hx <worktree>` in the agent tab's sibling, or `yazi` → Enter → Helix.

### 5.4 HTML — dev server + browser

- Dev command resolution order: `.dotdev:dev_command` → `.dotdev:dev_run` → `package.json` `scripts.dev|start|serve` (read with `jq`).
- Runs in the task's pane in the **web tab** (§9). `dot web open <task>` runs `open "$dev_url"`.
- Ready detection: `herdr pane wait-output <web_pane> --match "$dev_ready" --timeout 60000` before reporting success. `dev_ready` defaults to `Local:` (Vite/Astro) or the `dev_url` host:port.
- No terminal browser in the MVP path; `w3m`/`carbonyl` remain optional extras.

---

## 6. Git wiring (delta + difftastic)

`configs/git/files/config` → `~/.config/git/config`:

```ini
[core]
	pager = delta
	editor = hx

[interactive]
	diffFilter = delta --color-only

[delta]
	navigate = true
	side-by-side = true
	line-numbers = true
	syntax-theme = TwoDark
	features = line-numbers decorations
	true-color = auto

[delta "decorations"]
	commit-decoration-style = bold yellow box ul
	file-style = bold yellow ul
	file-decoration-style = none

[diff]
	algorithm = histogram
	colorMoved = default

[difftool]
	prompt = false

[difftool "difftastic"]
	cmd = difft "$LOCAL" "$REMOTE"

[merge]
	conflictStyle = zdiff3

[alias]
	dft   = "!f() { GIT_EXTERNAL_DIFF=difft git diff \"$@\"; }; f"
	dfst  = "!f() { GIT_EXTERNAL_DIFF=difft git diff --staged \"$@\"; }; f"
	dshow = "!f() { GIT_EXTERNAL_DIFF=difft git show \"$@\"; }; f"
	review = "!f() { GIT_EXTERNAL_DIFF=difft git diff \"${1:-$(git merge-base HEAD origin/HEAD)}\"...HEAD; }; f"
	lg    = log --graph --oneline --decorate --all
```

Why this shape:

- **delta is the pager** — every `git diff`, `git show`, `git log -p` gets side-by-side syntax-aware diffs for free.
- **difftastic is opt-in** — `git dft`, `git dfst`, `git dshow`, `git difftool -t difftastic`. We deliberately avoid `[diff] external = difft` because it breaks `git add -p`, `git stash -p`, and many tools that parse diff output (difftastic's own docs recommend the alias approach: <https://difftastic.wilfred.me.uk/git.html>).
- **`~/.gitconfig` is untouched** — it keeps `user.name`/`user.email`. Git reads `~/.config/git/config` and `~/.gitconfig` in the global scope; `~/.gitconfig` wins conflicts (it has none).
- `dot review --difft` uses the same `GIT_EXTERNAL_DIFF=difft` mechanism, so the CLI and the git aliases share one code path.

Verification: `git config --list | grep -E 'core.pager|difftool|alias.dft'`; `git dft HEAD~1`; `git config --global core.pager` → `delta`.

---

## 7. Configuration files

### 7.1 `.dotdev` (repo-local, flat `key = value`)

Lives in the repo root. All keys optional. `#` comments. Parsed by `dot` with a two-line `cfg_get`.

```
# .dotdev — agentic dev config for this repo
name          = web-dashboard          # workspace + tab label base (default: repo basename)
base          = main                   # worktree base ref (default: origin/HEAD → main)
worktree_root = ~/.herdr/worktrees     # parent; final path = <root>/<repo>/<task-id>
agent         = pi                     # herdr agent kind: pi | opencode | claude | codex
agent_args    = --model kimi-k3        # passed after `--` to `agent start`
dev_command   = bun run dev
dev_url       = http://localhost:5173
dev_ready     = Local:                 # substring for `pane wait-output`
review        = delta                  # delta | difft | lazygit
```

### 7.2 `.dotdev` vs `dot-cli.md` configs

`.dotdev` is *per-repo runtime* state (never installed into `~/.config`). It is not a `dot` config package. It is read by `dot` runtime verbs only.

---

## 8. Herdr layout model

### 8.1 Topology

```
workspace  <repo>                     ← exactly one per project
├── tab    review                     ← exactly one per workspace
│   ├── pane  review:<task-a>         ← one per DIRTY worktree
│   └── pane  review:<task-b>
├── tab    web                        ← exactly one per workspace
│   ├── pane  dev:<task-a>            ← one dev server per task
│   └── pane  dev:<task-b>
├── tab    <task-a>                   ← one AGENT tab per task
│   └── pane  agent:<task-a>
└── tab    <task-b>
    └── pane  agent:<task-b>
```

### 8.2 Naming

| Object | Value | Example |
|---|---|---|
| Workspace label | repo basename (`name`) | `web-dashboard` |
| Review tab label | literal `review` | `review` |
| Web tab label | literal `web` | `web` |
| Agent tab label | task id | `feat-add-oauth-login` |
| Review pane label | `review:<task id>` | `review:feat-add-oauth-login` |
| Web pane label | `dev:<task id>` | `dev:feat-add-oauth-login` |
| Agent pane label | `agent:<task id>` | `agent:feat-add-oauth-login` |
| Herdr agent name | task id | `feat-add-oauth-login` |
| Git branch | task id | `feat-add-oauth-login` |
| Worktree dir | `<root>/<repo>/<task id>` | `~/.herdr/worktrees/web-dashboard/feat-add-oauth-login` |

Task panes are labelled because `herdr pane split` has no `--label`; labels are applied with `herdr pane rename <pane> <label>`.

### 8.3 `dot up` — reconcile layout (idempotent)

```
1. repo_root, repo = detect (git rev-parse --show-toplevel, basename)
2. ws = $HERDR_WORKSPACE_ID if its label == repo
        else match label==repo in `herdr workspace list`
        else `herdr workspace create --cwd <repo_root> --label <repo> --no-focus`
           → .result.workspace.workspace_id
3. ensure tab "review": find in `herdr tab list --workspace "$ws"`;
        else `herdr tab create --workspace "$ws" --cwd <repo_root> --label review --no-focus`
           → .result.tab.tab_id, .result.root_pane.pane_id
4. ensure tab "web": as above, --label web
5. reconcile task panes:
        for each task in state, dirty? = `git -C <wt> status --porcelain`
          dirty  → ensure a review pane exists (create if absent)
          clean  → close its review pane (config: review.close_when_clean = true|false)
6. persist state; print a one-line summary
```

### 8.4 `dot task new` — create a task

```
dot task new feat add oauth login --prompt "Implement OAuth login…"

1. task = `dot name feat add oauth login`           # feat-add-oauth-login
2. repo, base, root, agent from .dotdev
3. wt = <root>/<repo>/<task>
4. git -C <repo> worktree add -b <task> <wt> <base>
5. agent tab:
     tab=$(herdr tab create --workspace "$ws" --cwd "$wt" --label "$task" --no-focus)
     pane=$(jq -r .result.root_pane.pane_id <<<"$tab")
     herdr pane rename "$pane" "agent:$task"
     [--no-agent] or: herdr agent start "$task" --kind "$agent" --pane "$pane" -- $agent_args
6. review pane:
     rp=$(herdr pane split "$review_tail" --direction down --cwd "$wt" --no-focus | jq -r .result.pane.pane_id)
     herdr pane rename "$rp" "review:$task"
     herdr pane run "$rp" "$(review_cmd "$wt")"        # delta|difft|lazygit
     review_tail=rp
7. web pane:
     wp=$(herdr pane split "$web_tail" --direction down --cwd "$wt" --no-focus | jq -r .result.pane.pane_id)
     herdr pane rename "$wp" "dev:$task"
     herdr pane run "$wp" "$dev_command"
     herdr pane wait-output "$wp" --match "$dev_ready" --timeout 60000   # best-effort
     web_tail=wp
8. if --prompt: herdr agent prompt "$task" "$prompt" --wait --timeout 900000
9. state[task] = {branch,wt,tab,pane,review_pane,web_pane,created_at}; persist
10. --focus ? `herdr tab focus <agent tab>` : leave focus untouched
```

`review_tail`/`web_tail` are persisted so repeated splits stack into a clean vertical column (never nest). Splitting the tail pane downward is what keeps the column tidy.

### 8.5 `dot task finish` — tear down

```
1. refuse if the agent state is `working` unless --force
2. herdr tab close <agent tab>            (kills the agent cleanly)
3. herdr pane close <review pane>; herdr pane close <web pane>
4. stop the dev process (closing the pane kills it; verify with `herdr pane process-info`)
5. dirty check: if dirty and not --keep, refuse and print `dot review <task>`
6. merge flow:
     --merge → git -C <repo> merge --no-ff <task>; git worktree remove <wt>; git branch -d <task>
     --pr    → git -C <wt> push -u origin <task>; gh pr create --fill; keep worktree
     --keep  → keep worktree + branch; just close tabs
7. state.delete(task); persist
```

---

## 9. Why we diverge from Herdr's worktree feature (R2)

Herdr 0.9.0 ships `herdr worktree create|open|remove` and `worktree list` ("List worktree **workspaces**"), plus `workspace close --group` which "closes the primary workspace and its linked worktree workspaces." That model is **one worktree ≈ one workspace, grouped with the project**.

The requested model is **one workspace per project**, with worktrees demoted to **tabs**. They cannot both be true. We take tabs because:

- A single workspace keeps the sidebar to one row per project; tasks are tabs, which is the requested mental model.
- The review tab can show *several* worktrees side by side; Herdr's grouped workspaces would spread them across the sidebar.
- The web tab aggregates dev servers for all tasks in one place.

**Costs we accept:** we lose `herdr worktree`'s git-trust prompts, its managed directory, and any future worktree-aware Herdr features. We manage `git worktree` ourselves and store paths under Herdr's configured `~/.herdr/worktrees` so they remain conventional.

**Escape hatch:** `.dotdev` may add `worktree_model = tabs | herdr` in a later phase; `herdr` mode would delegate to `herdr worktree create` and accept one workspace per task.

---

## 10. Naming convention (canonical)

```
task_id := "<type>-<slug>"
type    := feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert
slug    := 2 to 3 words, [a-z0-9]+, joined by "-"
```

Algorithm (`dot name <type> <words…>`):

1. Validate `type` against the set (allow `--type-any` to bypass).
2. Normalize each word: lowercase, strip non-`[a-z0-9]`, drop empties.
3. Take the first 2 words; take a 3rd only if the result still fits.
4. `candidate = type + "-" + slug`.
5. While `len(candidate) > 32`: drop the last word; if one word remains, truncate it at a word-ish boundary. (32 is Herdr's agent-name cap.)
6. On collision inside the workspace, append `-2`, `-3`, … (and re-trim to 32).

Examples:

| Input | task_id | len |
|---|---|---|
| `feat add oauth login` | `feat-add-oauth-login` | 20 |
| `fix null pointer crash` | `fix-null-pointer-crash` | 23 |
| `refactor authentication middleware` | `refactor-authentication` | 23 |
| `chore bump deps` | `chore-bump-deps` | 15 |

`task_id` is the single source of truth for branch, worktree dir, tab label, pane labels, and Herdr agent name — so everything is `grep`-able by one string.

---

## 11. Components: plugin + skill

### 11.1 `dot.worktree` — Herdr plugin

Repository: `configs/herdr-plugin-dot-worktree/files/` → staged to `~/.config/dot/plugins/dot.worktree`, linked with `herdr plugin link`, enabled with `herdr plugin enable`.

`herdr-plugin.toml`:

```toml
id = "dot.worktree"
name = "dot Worktree"
version = "0.1.0"
min_herdr_version = "0.9.0"
description = "Tab-per-task worktrees: new task, finish task, review, dev server"

[[actions]]
id = "new-task"
title = "New task…"
contexts = ["workspace"]
command = ["bash", "bin/new-task.sh"]

[[actions]]
id = "finish-task"
title = "Finish task…"
contexts = ["workspace"]
command = ["bash", "bin/finish-task.sh"]

[[actions]]
id = "apply-layout"
title = "Reconcile layout"
contexts = ["workspace"]
command = ["bash", "bin/apply-layout.sh"]

[[actions]]
id = "open-review"
title = "Open review panes"
contexts = ["workspace"]
command = ["bash", "bin/open-review.sh"]

[[panes]]
id = "board"
title = "Tasks"
placement = "overlay"
command = ["bash", "bin/task-board.sh"]

[[link_handlers]]
id = "github-issue"
title = "New task from issue"
pattern = "^https://github\\.com/[^/]+/[^/]+/(issues|pull)/[0-9]+$"
action = "new-task"

[[events]]
on = "worktree.created"
command = ["bash", "bin/apply-layout.sh"]
```

Every script is thin: it reads `HERDR_BIN_PATH`, `HERDR_PANE_ID`, `HERDR_WORKSPACE_ID` and calls `dot`:

- `new-task.sh`: prompt for `<type> <words…>` (via `gum`, already installed) → `dot task new …`
- `finish-task.sh`: `dot task list --json | gum choose` → `dot task finish …`
- `apply-layout.sh`: `dot up`
- `open-review.sh`: focus the review tab and step panes
- `task-board.sh`: `dot task list --watch`, refreshed every 2s

State: the plugin never keeps its own state; `dot` owns `~/.local/state/dot/dev/state.json`.

> Verify at build time: event name `worktree.created` and `contexts` values against `herdr plugin action` / the installed 0.9.0 schema. If `worktree.created` is unavailable, the `[[events]]` block is dropped and layout is driven purely by actions + `dot up`.

### 11.2 `herdr-subagents` — Pi skill

Installed to `~/.pi/agent/skills/herdr-subagents/` (symlinked by `dot`). Structure:

```
herdr-subagents/
├── SKILL.md
└── scripts/
    ├── spawn.sh     # worktree + new tab + agent start
    ├── wait.sh      # herdr agent wait
    └── collect.sh   # herdr agent read
```

`SKILL.md` (skeleton):

```markdown
---
name: herdr-subagents
description: Delegate work to subagents in Herdr. Use when a task should be
  parallelized across agents or isolated in its own worktree. Requires HERDR_ENV=1.
---

# Herdr subagents

Guard: `test "${HERDR_ENV:-}" = 1`.

## Rule: subagents get a NEW TAB, not a pane
Deliberate override of `herdr --skill`. Never `pane split` for a subagent.

## Spawn
scripts/spawn.sh <type> <word>… [--prompt TEXT]
  → dot task new <type> <word>… --kind pi --prompt TEXT --no-focus
  → prints the task id and agent tab id

## Wait / collect
herdr agent wait <task> --until done --timeout 900000
herdr agent read <task> --source recent-unwrapped --lines 200

## Full skill
The Herdr CLI is authoritative: run `herdr --help`, `herdr agent`, `herdr tab`.
Read IDs from JSON (`.result.*`), never predict them.
```

`spawn.sh` is literally `exec dot task new "$@" --kind pi --no-focus` plus emitting the new tab id; `wait.sh`/`collect.sh` wrap `herdr agent wait|read`. The naming helper (`dot name`) guarantees the subagent's tab, branch, and agent name all match.

**Coordination pattern** (what the skill enables):

```
lead agent (agent tab A)
  └─ dot task new feat add oauth login --prompt "…"   → agent tab B, worktree B
  └─ dot task new test oauth callback   --prompt "…"   → agent tab C, worktree C
  └─ herdr agent wait B --until done --timeout 900000
  └─ herdr agent read B --source recent-unwrapped --lines 200
  └─ dot task finish B --pr
```

---

## 12. Transcripts

**Source of truth:** Pi's JSONL at `~/.pi/agent/sessions/--<cwd>--/<ts>_<id>.jsonl` (tree of `id`/`parentId`; typed blocks `text`, `thinking`, `toolCall`, `toolResult`, `image`). Herdr already reports each agent's session path as `agent_session.value` (source `herdr:pi`) in `herdr agent list`.

### 12.1 `dot transcript` surface

| Subcommand | Behavior |
|---|---|
| `path <task\|--session ID\|--current>` | Resolve and print the JSONL path (from `herdr agent list` when a task is given; else pick from `~/.pi/agent/sessions`). |
| `render … [-o out.html]` | jq → single-file HTML along the active branch: user/assistant text, collapsible `thinking` and `toolCall`/`toolResult` via `<details>`, timestamps, token/cost footer. Then `open` unless `-o`. |
| `open …` | `open <rendered.html>`. |
| `share …` | `gh gist create <rendered.html>` (or print the exact `pi` `/share` steps for an interactive share). |
| `stats …` | Aggregate: tool-call counts by name, `isError` rate per tool, turns, tokens (input/output/cache), cost, wall-clock. This is the "identify improvements" view. |
| `focus <task>` | `herdr tab focus` the agent tab so the human can run Pi's interactive `/tree`. |

### 12.2 Pi built-ins we surface, not reimplement

- `/tree` — interactive branch navigation and filtering (no-tools / user-only / labeled-only).
- `/export [file]` — Pi's own HTML export.
- `/share` — private-gist HTML link.

`dot transcript focus` exists because `/tree` is interactive and must run in the agent's pane; `render`/`stats` exist because they must be headless and scriptable.

### 12.3 jq renderer sketch

```jq
def esc: @html;
[ .[]
  | select(.type == "message")
  | .message
  | if   .role == "user"        then "<section class=u><h3>user</h3><pre>\(.content|tostring|esc)</pre></section>"
    elif .role == "assistant"   then "<section class=a><h3>assistant</h3>" +
                                     ([.content[] |
                                        if .type=="text"      then "<pre>\(.text|esc)</pre>"
                                        elif .type=="thinking" then "<details><summary>thinking</summary><pre>\(.thinking|esc)</pre></details>"
                                        elif .type=="toolCall" then "<details><summary>\(.name)</summary><pre>\(.arguments|tostring|esc)</pre></details>"
                                        else empty end] | join("")) + "</section>"
    else empty end
] | join("\n")
```

(Wrapped in an HTML shell with embedded CSS; `@html` handles escaping. Exact entry shape to be confirmed against a real v3 session at build time — the renderer must tolerate unknown `type` values by ignoring them.)

### 12.4 Optional: auto-render on completion

A small Pi extension (`~/.pi/agent/extensions/dot-transcript.ts`, installed *beside* Herdr's managed `herdr-agent-state.ts`) can, on session end, call `dot transcript render` into `~/.local/state/dot/transcripts/<session-id>.html` and notify via `herdr notification show`. Deferred to v2.

---

## 13. Profiles

`profiles/mac.conf`:

```
zsh
starship
ghostty
herdr
herdr-plugin-dot-worktree
pi-skill-herdr-subagents
zellij
git
helix
yazi
glow
tmux
brewfile
uv-tools
skills
```

`profiles/server.conf`:

```
zsh
starship
herdr
herdr-plugin-dot-worktree
pi-skill-herdr-subagents
tmux
git
helix
yazi
glow
uv-tools
```

Differences: `ghostty` (mac-only), `brewfile` (mac-only), `zellij` (mac). `git`, `helix`, `yazi`, `glow`, the plugin, and the skill are on both — they are headless-safe.

---

## 14. Repository layout (deltas)

```
dotfiles/
├── dot                                   # NEW: config + runtime verbs (bash)
├── bootstrap.sh                          # NEW: curl entrypoint (dot-cli.md §12)
├── install.sh                            # legacy; becomes a shim → `dot apply --profile`
├── specs/
│   ├── dot-cli.md                        # unchanged (authoritative for config lifecycle)
│   └── agentic-dev-mvp.md                # this file
├── profiles/{mac,server}.conf
└── configs/
    ├── zsh/ starship/ ghostty/ herdr/ zellij/ tmux/ skills/ brewfile/ uv-tools/   # existing
    ├── git/                              # NEW
    ├── helix/                            # NEW
    ├── yazi/                             # NEW
    ├── glow/                             # NEW
    ├── herdr-plugin-dot-worktree/        # NEW
    │   ├── README.md manifest
    │   └── files/                        # herdr-plugin.toml + bin/*.sh
    └── pi-skill-herdr-subagents/         # NEW
        ├── README.md manifest
        └── files/                        # SKILL.md + scripts/*.sh
```

Runtime code lives inside `dot` itself (single file) plus `configs/herdr-plugin-dot-worktree/files/bin/*` and `configs/pi-skill-herdr-subagents/files/scripts/*`.

---

## 15. Build plan (phases)

Each phase is independently useful and testable.

**Phase 0 — this spec.** Agree R1–R9.

**Phase 1 — toolchain config packages.**
`git`, `helix`, `yazi`, `glow` configs + Brewfile additions (`helix`, `poppler`, `chafa`); `herdr` `post_apply` for integrations. Done when `dot apply git helix yazi glow` is green and `git config --list` shows delta + difftastic aliases.

**Phase 2 — `dot` runtime verbs + layout.**
`dot name`, `dot up`, `dot task new|list|finish`, `dot review`, `dot web`, `.dotdev` parsing, state file + `flock`. Done when `dot task new` from inside a Herdr project produces the full topology with correct labels.

**Phase 3 — `dot.worktree` plugin.**
Manifest, actions, board pane, link handler; `herdr plugin link/enable`; verified with `herdr plugin action`. Done when "New task…" appears in the Herdr workspace menu and the board overlay lists tasks.

**Phase 4 — `herdr-subagents` skill.**
`SKILL.md` + three scripts; symlinked by `dot`. Done when a Pi agent can spawn a subagent tab, wait, and read its output end-to-end.

**Phase 5 — transcripts.**
`dot transcript path|render|open|share|stats`. Done when a real Pi session renders to HTML with collapsible tool calls and `stats` prints per-tool error rates.

**Phase 6 — `dot` config-lifecycle MVP.**
`init/apply/status/doctor/update/edit/diff/list/info/profiles/cd` + store + lockfile, per `dot-cli.md`. `install.sh` becomes a shim.

**Phase 7 (deferred).** `add`, `bump`, `rollback`, `--ephemeral`, `--lock`, `parts/`, auto-render transcripts, `worktree_model = herdr`.

---

## 16. Acceptance tests

| # | Test | Expected |
|---|---|---|
| T1 | `dot doctor` | exit 0; git, jq, herdr, hx, glow, yazi, difft, delta all present |
| T2 | `git config --list \| grep -E 'core.pager\|difftool.difftastic'` | `core.pager=delta`, `difftool.difftastic.cmd=difft …` |
| T3 | `git dft HEAD~1` | structural diff; `git add -p` still works (no `diff.external`) |
| T4 | `glow README.md` (in a Herdr pane) | rendered headings/tables/code |
| T5 | `yazi` (in a Herdr pane) | images preview inline; PDFs preview via `pdftoppm`; Enter opens in `hx` |
| T6 | `dot name feat add oauth login` | `feat-add-oauth-login` |
| T7 | `dot name refactor authentication middleware` | ≤ 32 chars, no mid-word cut |
| T8 | `dot up` (inside a Herdr project) | `herdr tab list` shows `review` and `web`; idempotent on re-run |
| T9 | `dot task new feat add oauth login --no-agent` | branch + worktree created; `herdr tab list` shows `feat-add-oauth-login`; review + web panes exist with labels `review:…`/`dev:…` |
| T10 | `herdr agent list \| jq '.result.agents[] \| select(.agent=="pi") \| .agent_session.value'` | non-null path (Herdr/pi integration current) |
| T11 | Pi skill: spawn → wait → read | subagent runs in a **new tab** with its own worktree; output readable |
| T12 | `dot transcript render --current` | valid HTML with `<details>` for thinking/tool calls; opens in browser |
| T13 | `dot transcript stats --current` | per-tool counts, `isError` rate, tokens, cost |
| T14 | `dot task finish <task> --merge` | agent tab + panes closed; worktree removed; branch merged/deleted |

---

## 17. Risks & open questions

| # | Risk / question | Mitigation |
|---|---|---|
| 1 | **Herdr worktree model conflict** (R2) | Documented; we bypass `herdr worktree`. Revisit if Herdr adds tab-scoped worktrees. |
| 2 | `dot` shadows Graphviz's `dot` if `~/.local/bin` precedes `/opt/homebrew/bin` | `dot doctor` warns when `command -v dot` ≠ `~/.local/bin/dot`. Fallback name `dotx` if it becomes a problem. |
| 3 | Herdr agent names cap at 32 chars | Enforced in `dot name`; task id ≤ 32 everywhere. |
| 4 | `herdr pane split` has no `--label` | Use `herdr pane rename`. |
| 5 | `herdr plugin` event/action schema may differ in 0.9.0 | Verify with `herdr plugin action`; drop `[[events]]` if unsupported (actions suffice). |
| 6 | `.dotdev` flat parser can't express nesting | Flat keys only; revisit TOML (`yq -p toml`) if it hurts. |
| 7 | Splitting `review_tail` repeatedly can make panes too short | Emit a warning past N tasks; support `review` tab zoom + a future "single review pane with a task switcher". |
| 8 | Closing a tab may not reap the dev process | Verify with `herdr pane process-info`; add `pkill -f` by worktree path if needed. |
| 9 | Session JSONL v3 shape drift | Renderer ignores unknown `type`s; `stats` tolerates missing fields. |
| 10 | `glow.yml` key names unverified | Confirm at build; degrade to env-only config. |

---

## 18. Deltas to `dot-cli.md`

1. New verb family in the CLI table (§11 there): `up`, `task`, `review`, `web`, `transcript`, `name`. `dot-cli.md` remains authoritative for the config verbs.
2. New config packages: `git`, `helix`, `yazi`, `glow`, `herdr-plugin-dot-worktree`, `pi-skill-herdr-subagents`.
3. New categories in use: `editor`, `vcs`, plus existing `agents`, `terminal`.
4. `Brewfile` additions: `helix`, `poppler`, `chafa`.
5. `profiles/mac.conf` and `profiles/server.conf` updated per §13.
6. `configs/herdr/manifest` gains a `post_apply` that installs the Pi/OpenCode integrations.
7. New runtime state path: `~/.local/state/dot/dev/state.json` (alongside `installed.json`).
8. No change to the store, lockfile, semver, or ephemeral models.
