# rex

[Rex](https://www.superlogical.com/rex/docs) — a terminal multiplexer app.
Themed to match Ghostty: **TokyoNight Night**, imported from Ghostty's own
theme file, so the colors are exact.

## What's captured

| File | Lands at | How |
|------|----------|-----|
| `shortcuts.json` | `~/Library/Application Support/com.superlogical.rex/Shortcuts/shortcuts.json` | symlink |
| `settings.json` | `~/.config/dot/rex-settings.json` | symlink, then written into preferences by `post_apply` |
| `rex-settings` | `~/.config/dot/rex-settings` | helper script (`apply` / `capture`) |

Rex keeps its settings in macOS preferences (`com.superlogical.rex`), next
to window frames and session state that change constantly, so the plist
can't be symlinked. `settings.json` is a typed snapshot of just the
`Workspace.*` settings; `post_apply` writes each key with `defaults write`.
The custom theme lives in `data["Workspace.customThemes"]` as readable JSON.
Session state (`lastFocusedSession`, `programActivitySeen`) is never captured.

There's no `~/.config/rex/init.lua` yet; add one here as a third file when
you start binding keys or defining actions.

## Changing settings

Rex's settings are edited in its UI, so the loop is capture → commit:

```bash
~/.config/dot/rex-settings capture > ~/git/dotfiles/configs/rex/files/settings.json
dot bump rex patch    # then commit, and `dot update rex` on other machines
```

Relaunch Rex after `dot apply rex` on a machine where it was already running.

## Gotchas

- If Rex rewrites `shortcuts.json` (editing shortcuts in its Settings), it can
  replace the symlink with a plain file and `dot status` shows `modified`.
  Copy the file back into `files/` and bump.
- The light theme is Rex's built-in `buttercream-diner`; only dark mode
  uses TokyoNight Night.
