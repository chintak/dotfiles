# claude

Versions the **hand-authored** parts of Claude Code's user config. It is
standalone: `dot apply claude` works on a machine without opencode. Shared
content (`AGENTS.md`, skills, MCP servers) comes from `shared/` (see
`shared/README.md`). Everything else in `~/.claude/` is runtime state and
stays independent.

- `files/CLAUDE.md` → `~/.claude/CLAUDE.md`. It holds only `@AGENTS.md`, so
  the instructions exist once.
- `files/AGENTS.md` → `~/.claude/AGENTS.md` (git symlink to
  `shared/AGENTS.md`).
- `files/skills/<name>` → `~/.claude/skills/<name>`, one manifest line per
  skill (git symlink to `shared/skills`). Per-skill links leave rex, langfuse,
  synced, and anything else in `~/.claude/skills/` alone.
- `files/agents/` → `~/.claude/agents/`. `do`, `focus`, `critique`, and
  `review` are ported from `opencode/files/agents/` with Claude frontmatter
  (`name`, `description`, `disallowedTools`).
  - opencode's path-scoped edit/shell permissions have no subagent
    equivalent, so those guards are prose-only here.
  - `focus` is a primary agent: run `claude --agent focus`, since subagents
    can't spawn subagents.
- `files/mcp.json` → `~/.config/dot/claude/mcp.json`. **Generated** by
  `shared/render-mcp.py`; don't edit it. `mac-work` gets `mcp-work.json`
  (none), like opencode's work variant.
- `files/bin/` → `~/.config/dot/claude/bin/`
  - `sync.sh` is the post_apply. It adds or replaces a server in
    `~/.claude.json` only when its config differs. It also removes servers
    it added earlier that `mcp.json` dropped (tracked in `.managed-mcp`).
  - `mcp-bearer.sh VAR` is the `headersHelper` for bearer-token servers.
    Token sources: `$VAR`, then keychain `dot-mcp-VAR`, then the OpenCode
    daemon env (optional, used only if opencode is installed). On a
    Claude-only machine:
    `security add-generic-password -U -a "$USER" -s dot-mcp-GITHUB_PERSONAL_ACCESS_TOKEN -w`.

**Deliberately not versioned:**
- `settings.json` / `settings.local.json`: Claude Code rewrites these
  (`/config`, permission grants). Symlinking them would leave the store
  permanently "modified".
- `~/.claude.json`, `plugins/`, `projects/`, `sessions/`, and the
  `~/.claude/skills/` entries dot didn't install: owned by the app or other
  integrations.
