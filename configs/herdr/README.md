# herdr

The multiplexer, and the centre of the setup. Prefix is `ctrl+b`; most actions
also have prefix-free chords plus the always-working `prefix+…` fallback.

Keymap contract (full matrix lives in `files/config.toml` header comments):

- **Tabs:** `shift+alt+left/right`, `alt+[` / `alt+]`, `cmd+shift+[` / `]`;
  reliable twins `ctrl+alt+[ / ]`.
- **Panes:** `cmd+alt+arrows` and `shift+alt+k/j`, `ctrl+alt+h/j/k/l`
  reliable twins.
- **Inside-pane apps (Helix, opencode, pi) only receive what herdr doesn't
  capture.** Plain `alt+left/right` (Helix word motion), insert-mode `Alt-d` /
  `Alt-Backspace`, and all `ctrl+…` / unmodified keys pass through. herdr's
  `alt+d/u/i/n` shadow the same Helix normal-mode Alt chords — see the shadow
  map in `helix/files/config.toml`. opencode and pi keep their defaults; none
  of their core chords overlap herdr's set.

- **`post_apply` installs the Pi + OpenCode integrations.** Those make herdr a
  *lifecycle authority* — real `working`/`blocked`/`done` events from agent
  hooks instead of screen scraping.
- **`agent_panel_sort = "spaces"`** keeps sidebar rows stable so the
  `shift+alt+1..9` agent-jump keys always land on the same agent.
- **`[worktrees]`** points at `~/.herdr/worktrees` for one-branch-per-agent.
- **`shell_mode = "auto"`** starts a login shell on macOS so Homebrew's PATH is
  present in every pane.

Reload after edits: `herdr server reload-config`.
