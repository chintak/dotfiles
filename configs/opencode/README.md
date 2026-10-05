# opencode

Versions the **hand-authored** parts of `~/.config/opencode/`; everything
else in that directory is runtime state the app or the herdr integration
owns and stays independent.

- `files/opencode.jsonc` → `~/.config/opencode/opencode.jsonc` — agent
  settings: LSP + formatters on, `.worktrees/` worktree directory for the
  `do` agent, and the MCP servers wired here (not into Pi): Roblox Studio
  (local), alphaxiv (remote, OAuth via `/mcps`), HuggingFace and GitHub
  (remote, `oauth: false` + Bearer `{env:HF_TOKEN}` / `{env:GITHUB_TOKEN}`),
  and Exa (local, `{env:EXA_API_KEY}`). See **Environment & secrets** below.
- `files/tui.jsonc` → `~/.config/opencode/tui.jsonc` — loads the herdr
  TUI session plugin (`herdr-tui-session.js`), which the herdr opencode
  integration installs and keeps updated.
- `files/agents/` → `~/.config/opencode/agents/` — agent definitions
  (`do.md`). Edit in the repo; new panes read them at startup.
- `files/skills/` → `~/.config/opencode/skills/` — reusable skills
  (`ship/SKILL.md`). Edit in the repo and re-apply.
- `files/AGENTS.md` → `~/.config/opencode/AGENTS.md` — one-line pointer so
  agents edit the repo + `dot apply opencode` instead of the live symlinks.

## Environment & secrets

`{env:NAME}` for MCP is resolved in the **background service**, not your
shell. The service is usually started by launchd or the desktop app, so it
only sees variables persisted *for it*:

- Shell-level values live in `~/.env` (literal, no `$(...)`) and are sourced
  from `~/.zshenv`.
- Persist each into the daemon — this is what makes MCP auth work on a fresh
  machine:

  ```bash
  opencode service set env GITHUB_TOKEN "$GITHUB_TOKEN"
  opencode service set env HF_TOKEN     "$HF_TOKEN"
  opencode service set env EXA_API_KEY  "$EXA_API_KEY"
  opencode service stop && opencode service start
  opencode api get /api/mcp        # expect all "connected"
  ```

- Persisted env lives in `~/.config/opencode/service.json` (`0600`); read with
  `opencode service get env NAME`, remove with `opencode service unset env NAME`.

If a remote server reports `HTTP 400 Authorization header is badly formatted`,
the daemon is sending an empty `Bearer ` — the credential never reached it.

**Deliberately not versioned:**
- `plugins/` — `herdr-agent-state.js` is installed and overwritten by the
  herdr integration on every update; dot would fight it. Add custom
  hooks/plugins beside it instead (per its own header).
- `cli.json` / `service.json` — 0600 runtime state incl. local server
  credentials.
- `package.json` + `node_modules/` — plugin dependencies managed by the
  herdr integration.
- `herdr-opencode/`, `herdr-tui-session.js` — installed by the herdr
  integration, not by dot.
