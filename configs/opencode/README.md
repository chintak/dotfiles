# opencode

Versions the **hand-authored** parts of `~/.config/opencode/`; everything
else in that directory is runtime state the app or the herdr integration
owns and stays independent.

- `files/opencode.jsonc` → `~/.config/opencode/opencode.jsonc` — agent
  settings: LSP + formatters on, `.worktrees/` worktree directory for the
  `do` agent, and the Roblox Studio MCP server wired here (not into Pi).
- `files/tui.jsonc` → `~/.config/opencode/tui.jsonc` — loads the herdr
  TUI session plugin (`herdr-tui-session.js`), which the herdr opencode
  integration installs and keeps updated.
- `files/agents/` → `~/.config/opencode/agents/` — agent definitions
  (`do.md`). Edit in the repo; new panes read them at startup.
- `files/skills/` → `~/.config/opencode/skills/` — reusable skills
  (`ship/SKILL.md`). Edit in the repo and re-apply.
- `files/AGENTS.md` → `~/.config/opencode/AGENTS.md` — one-line pointer so
  agents edit the repo + `dot apply opencode` instead of the live symlinks.

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
