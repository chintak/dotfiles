# rex

[Rex](https://www.superlogical.com/rex/docs) — a terminal multiplexer app,
set up to feel like the Ghostty + herdr setup:

- **Look:** TokyoNight Night imported from Ghostty's own theme file (exact
  colors, selection included), JetBrainsMono Nerd Font Mono 16, block cursor
  with no blink. Programs can still change the cursor (Helix's insert bar).
- **Keys:** Option acts as Alt, and `init.lua` binds herdr's direct chords to
  Rex's native actions: herdr tab → Rex tab, pane → pane, workspace →
  session. `cmd+1..9` jumps to the Nth session via a small `goto_session`
  action. The `ctrl+b` prefix is left free for tmux inside a pane.
- **Helix:** `alt+left/right` send real alt+arrows and `cmd+left/right` send
  Home/End, like the Ghostty overrides.

- **Agents:** herdr's agent jumping, across every session. `alt+tab` /
  `shift+alt+tab` cycle agent panes, `shift+alt+1..9` jump to the Nth, and
  `cmd+shift+a` opens the **agent switcher**: a floating fzf list of every
  agent pane with its state (needs you / working / done / idle), latest
  message, directory, and a live preview of its screen. Enter jumps.

Not carried over: Ghostty's quick terminal (global hotkey), window padding
and hidden titlebar (Rex has no equivalent setting), cursor thickness, and
herdr's agent chords (`alt+tab`, `shift+alt+1..9`).

## What's captured

| File | Lands at | How |
|------|----------|-----|
| `init.lua` | `~/.config/rex/init.lua` | symlink; `post_apply` runs `rex config reload` |
| `shortcuts.json` | `~/Library/Application Support/com.superlogical.rex/Shortcuts/shortcuts.json` | symlink |
| `settings.json` | `~/.config/dot/rex-settings.json` | symlink, then written into preferences by `post_apply` |
| `rex-agents` | `~/.config/dot/rex-agents` | the switcher (`cmd+shift+a`); also `list`, `preview N`, `goto N` |
| `pi-rex-status.ts` | `~/.pi/agent/extensions/rex-status.ts` | pi extension: reports state to Rex |
| `rex-settings` | `~/.config/dot/rex-settings` | helper script (`apply` / `capture`) |

Rex keeps its settings in macOS preferences (`com.superlogical.rex`), next
to window frames and session state that change constantly, so the plist
can't be symlinked. `settings.json` is a typed snapshot of just the
`Workspace.*` settings; `post_apply` writes each key with `defaults write`.
The custom theme lives in `data["Workspace.customThemes"]` as readable JSON.
Session state (`lastFocusedSession`, `programActivitySeen`) is never captured.

## How agents are found

A pane is an agent when a known agent (`claude-code`, `pi`, `opencode`,
`codex`) reports its state with the Program Status Protocol (OSC 7501), or
when one runs as the pane's foreground program. Claude Code reports natively;
pi via `pi-rex-status.ts` here; opencode via `rex-tui-status.js` in the
`opencode` package (a TUI plugin, since opencode V2's server is shared and only
the TUI knows which pane it's in). Both plugins write to `/dev/tty` and do
nothing outside Rex. pi has no permission prompts of its own, so it's
`blocked` only when an extension emits `rex:blocked` (or herdr's
`herdr:blocked`) on `pi.events` with `{ active, label }`.

The actions behind the keys live in `init.lua` (`agents`, `goto_agent`,
`next_agent`, `previous_agent`, `focus_agent`, `agent_switcher`) and show up in
the command palette under **Agents**. `rex do agents` prints the list as JSON.

## Changing settings

Rex's settings are edited in its UI, so the loop is capture → commit:

```bash
~/.config/dot/rex-settings capture > ~/git/dotfiles/configs/rex/files/settings.json
dot bump rex patch    # then commit, and `dot update rex` on other machines
```

Relaunch Rex after `dot apply rex` on a machine where it was already running.

## Gotchas

- Shortcuts set in the app (**Change Shortcut…**, stored in `shortcuts.json`)
  win over `init.lua`. If a binding seems dead, check there first.
- Copy-on-select stays **on** here. Ghostty has it off only because it's
  broken on macOS 26 in Ghostty 1.3.x.

- If Rex rewrites `shortcuts.json` (editing shortcuts in its Settings), it can
  replace the symlink with a plain file and `dot status` shows `modified`.
  Copy the file back into `files/` and bump.
- The light theme is Rex's built-in `buttercream-diner`; only dark mode
  uses TokyoNight Night.
