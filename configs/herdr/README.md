# herdr

The multiplexer, and the centre of the setup. Prefix is `ctrl+b`; most actions
also have prefix-free Mac chords (`alt+[`, `shift+alt+hjkl`).

- **`post_apply` installs the Pi + OpenCode integrations.** Those make herdr a
  *lifecycle authority* — real `working`/`blocked`/`done` events from agent
  hooks instead of screen scraping.
- **`agent_panel_sort = "spaces"`** keeps sidebar rows stable so the
  `shift+alt+1..9` agent-jump keys always land on the same agent.
- **`[worktrees]`** points at `~/.herdr/worktrees` for one-branch-per-agent.
- **`shell_mode = "auto"`** starts a login shell on macOS so Homebrew's PATH is
  present in every pane.

Reload after edits: `herdr server reload-config`.
