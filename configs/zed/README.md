# zed

Zed is the GUI editor and the agent surface on the Mac: Helix-style modal
editing, the Nordfox/Dayfox theme pair (system light/dark), and opencode wired
in as the model provider. Its three **hand-edited** config files are versioned
here; everything else in `~/.config/zed/` and `~/Library/Application
Support/Zed/` is runtime state.

- `files/settings.json` → `~/.config/zed/settings.json`
- `files/keymap.json` → `~/.config/zed/keymap.json`
- `files/tasks.json` → `~/.config/zed/tasks.json`

`platform = mac`: the settings embed a macOS-absolute MCP command and the
package is installed on `mac-personal` only (same guard as `ghostty` and
`brewfile`).

## Why these settings

`settings.json` is a **verbatim copy of the live file** (byte-identical on
first apply — no reordering, no reformatting), keys in Zed's own order.

| Setting | Why |
|---------|-----|
| `helix_mode: true` | Modal editing everywhere in Zed — selections and motions match hx, so the editor and the terminal editor agree. |
| `cursor_shape: block` + `cursor_blink: false` | Helix's block cursor, non-blinking so the caret doesn't pull the eye in a pane an agent is also writing to. |
| `theme.light` `Dayfox - opaque` / `theme.dark` `Nordfox - blurred` | System light/dark pair from the Fox family — warm, low-contrast themes that don't fight Ghostty's TokyoNight. The suffix is Zed's theme variant naming, so the pair follows the OS appearance automatically. |
| `format_on_save: modifications_if_available` | Formats on save only when the language server can format *changed* regions, so saving a large file doesn't reflow unrelated lines (keeps agent diffs reviewable). |
| `autosave: on_focus_change` | Writes a buffer when the window loses focus rather than on every keystroke or on a timer — the least intrusive policy when an agent is also touching files. |
| `focus_follows_mouse: { enabled: true }` | Clicking into a pane focuses it without a second click — matches herdr pane behaviour. |
| `buffer_font_family` / `agent_buffer_font_family` = `JetBrainsMono Nerd Font Mono` | The Nerd Font from the Brewfile cask; glyphs are PUA-only (see the root README), so the font must be explicit. Agent buffers are one point smaller to fit more tool output. |
| `agent_servers.*` | Registry entries for the external agent backends Zed can drive: `opencode-v2` (pinned `effort: high`, `model: opencode-go/deepseek-v4.1-flash`), plus `codex-acp` and `claude-acp` as `type: registry`. `agent.default_model` sets the default thread to `opencode` / `go/deepseek-v4.1-flash` with thinking and `effort: high`, so a new thread starts on the same model the opencode CLI uses. |
| `language_models.opencode.show_zen_models: false` | Trims the "Zen" model list from the picker — only the models actually used are offered. |
| `context_servers.Roblox_Studio.command` | Points Zed's agent at the Roblox Studio MCP binary (`/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`), the same server the opencode `mcp` block uses. **Absolute path by design** — it breaks if Studio moves; acceptable for a mac-personal-only package. |
| `agent.tool_permissions` / `agent.sandbox_permissions` | Default-allow tool calls with all network hosts allowed: the agent is expected to run builds and fetch, and Zed's prompt-per-call is the slow path. |
| `search.regex: true`, `search.center_on_match: true`, scroll margins `99` | Search opens in regex mode (the `rg` habit); matches are centred and the viewport keeps a wide scroll margin so the cursor never sits at the screen edge. |

## Keymap

`keymap.json` is a JSON array of `{ "context": …, "bindings": { "chord": "action" } }`
objects ([key-bindings docs](https://zed.dev/docs/key-bindings); the stock
bindings referenced below are in
[`default-macos.json`](https://github.com/zed-industries/zed/blob/main/assets/keymaps/default-macos.json)).
It ships one binding:

```json
[
  {
    "context": "Workspace",
    "bindings": {
      "cmd-alt-shift-n": "agent::ToggleNewThreadMenu"
    }
  }
]
```

- `cmd-alt-shift-n` is Zed's stock shortcut for `agent::ToggleNewThreadMenu`,
  but stock binds it **only** inside the `AgentPanel` context
  (`default-macos.json:255-261`), so it is dead while the editor has focus.
  Rebinding it in `Workspace` — the root context — makes it work anywhere.
- One `Workspace` block is deliberate. Precedence is by context depth: a
  binding on a lower node wins over one on a higher node, and **at the same
  level** user bindings (loaded after system ones) win over defaults. So the
  `Workspace` entry covers the editor, while inside the panel the stock
  `AgentPanel` binding resolves to the *same action* — a duplicate
  `AgentPanel` block would be noise, not a fix.
- **Quoting a selection into a thread is two steps, not one chord.**
  `cmd->` in the editor runs `agent::AddSelectionToThread`
  (`default-macos.json:155-166`, context `Editor && mode == full` — full mode,
  so Helix mode's normal mode does not have it), then `cmd-n` runs
  `agent::NewThread` from the agent panel (`default-macos.json:258`, context
  `AgentPanel`; also `AcpThread`, line 286). **No stock action combines
  "quote selection + open a new thread"**, so no combined chord is bound here —
  a fake one would have to be a `workspace::SendKeystrokes` macro, and
  asynchronous actions don't chain reliably through it.

`tasks.json` stays `[]`: no project tasks are defined. The tasks docs only
show populated arrays, so "Zed accepts an empty one" is an assumption, not a
proven format — acceptance is probed in the UI (`task: spawn`, see below). If
Zed rewrites the file to a non-empty shape, drop it from the manifest and take
a patch bump.

## What is deliberately not tracked

- `~/.config/zed/prompts/` — a LevelDB store written by the app; never
  hand-edited, never versioned.
- `~/Library/Application Support/Zed/` — macOS app state: `db/`, `threads/`
  (conversation history), `extensions/`, `languages/`. Machine state, not
  config.
- Tracking the whole directory instead (`files/zed/` → `~/.config/zed`) was
  rejected: `dot` supports directory entries, but it would swallow the
  `prompts/` LevelDB above.

**No secrets in `settings.json`.** Tokens never belong here; the
`context_servers` entry is a command path, not a credential. Real secrets live
in `~/.env` / `~/.config/localenvs/*.local` or are persisted for the opencode
daemon (`opencode service set env …`, see the root README).

## The reconcile loop

Zed's UI **writes its config files**, so unlike every other config here, the
store copy is mutable. The loop is always: capture first, then re-pin.

```bash
dot diff zed                  # what the UI changed vs the repo — do this BEFORE apply
# copy the wanted change into configs/zed/files/<file>
dot bump zed patch            # auto-commits "chore(zed): bump X -> Y" (dot:664)
dot apply zed
```

- **The bump is load-bearing.** `dot update` re-applies only when the repo
  version is newer (`dot:599`), so a content-only edit would not reach other
  machines. This deliberately differs from the content-only convention used
  for, say, the opencode `AGENTS.md`.
- **`dot apply zed` starts with `rm -rf` on the store** (`dot:211`), so an
  un-captured UI edit is silently destroyed. `dot diff zed` first, always.
- `dot edit zed` opens **only the first file** in the manifest —
  `settings.json` (`dot:492-493`). Keymap and tasks have no edit shortcut
  (`$EDITOR configs/zed/files/keymap.json`).

### Write-through, not symlink pinning

Zed canonicalizes paths before writing; the fix for "Zed deletes a symlinked
`settings.json`" ([zed#4469](https://github.com/zed-industries/zed/issues/4469))
landed in `v0.123.1-pre`. On a version carrying that fix, a UI edit **writes
through the symlink into `store/zed/1.0.0/`**:

- `dot status` reports **`modified`** (store content no longer matches the
  recorded hash), and the store stops pinning anything — `dot diff`,
  `dot rollback`, and the hash all read the mutated content.
- On a build that instead does temp+rename, the symlink is replaced and
  `dot status` reports **`drifted`** (never `broken` — that state means the
  store directory is missing).

Expected and accepted: this is the house doctrine of *drift detected, not
prevented*, applied to a config whose tool rewrites it.

- **No hot reload of a symlinked settings file**
  ([zed#38936](https://github.com/zed-industries/zed/issues/38936), closed as
  duplicate): after `dot apply zed`, a window reload may be needed for Zed to
  pick the file up.
- **`keymap.json` is the highest-drift file of the three.** Anything done in
  the keymap editor is written straight back to `keymap.json` — check
  `dot diff zed` after remapping, not just after a settings toggle.

### Pending user step: the drift probe

Not automatable, and **not yet run** — the branch above (`modified` vs
`drifted`) is inferred, not observed on the installed cask. Run once in the
Zed UI and record which one happens here:

```bash
# 1. In Zed: toggle any setting, add one keybinding in the keymap editor, spawn a task once
readlink ~/.config/zed/settings.json     # still a symlink → wrote through into the store
./dot diff zed                           # capture the UI edit BEFORE applying
./dot status --json | jq '.[] | select(.name=="zed") | .state'
./dot apply zed                          # re-pins; destroys the store edit unless it was copied first
```

Acceptance for the empty scaffolds is a UI probe too: `zed: open keymap file`
and `task: spawn` must open without an error toast.

## Deferred: extensions

Extension provenance is reproducible via `auto_install_extensions`, but adding
it would break byte-identity with the live file, so it is a **1.1.0
follow-up**. Currently installed (10): `dockerfile`, `html`,
`jetbrains-themes`, `just`, `latex`, `material-icon-theme`, `nvim-nightfox`,
`one-dark-pro`, `toml`, `tsgo`.
