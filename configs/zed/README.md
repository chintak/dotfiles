# zed

Zed is the GUI editor on the Mac: Helix-style modal editing, the
Nordfox/Dayfox theme pair (system light/dark), and Zed's own AI turned off —
agents run in opencode and herdr, not in Zed's panel. `settings.json` is
*captured* from the UI and pruned (see *Why these settings*); `keymap.json` and
`tasks.json` are hand-edited. Everything else in `~/.config/zed/` and
`~/Library/Application Support/Zed/` is runtime state.

- `files/settings.json` → `~/.config/zed/settings.json`
- `files/keymap.json` → `~/.config/zed/keymap.json`
- `files/tasks.json` → `~/.config/zed/tasks.json`

`platform = mac`: the settings embed a macOS-absolute MCP command and the
package is installed on `mac-personal` only (same guard as `ghostty` and
`brewfile`).

## Why these settings

`settings.json` is a **capture-then-prune** of the live file: it starts as a
byte copy of what Zed last wrote, and is hand-edited *only* where a key is
deliberately retired — every prune is recorded here. Keys are otherwise in
Zed's own order, because Zed rewrites this file itself (see *The reconcile
loop*), so "its order" is whatever Zed last wrote; the one exception is the
`auto_install_extensions` slot at the end of the object, which `jq` appends and
Zed re-places on its next write.

The prune is a copy-pasteable expression, not a remembered step — a plain
re-capture *reverts* `disable_ai: true` and resurrects both retired keys:

```bash
jq 'del(.agent_servers, .language_models)
    | .auto_install_extensions = {dockerfile: true, html: true, "jetbrains-themes": true,
        just: true, latex: true, "material-icon-theme": true, "nvim-nightfox": true,
        "one-dark-pro": true, toml: true, tsgo: true}' \
   configs/zed/files/settings.json > /tmp/s && mv /tmp/s configs/zed/files/settings.json
```

Verified on `jq-1.8.2` against the 2026-10-23 11:40 capture: the expression
preserves the 2-space indent and the float literals (`13.0`, `15.0`, `99.0`),
and yields 2 hunks / 25 deletions / 12 insertions against the raw capture —
`agent_servers` and `language_models` gone, `auto_install_extensions` added,
every other byte unchanged. Byte preservation is a **jq-version property**: on
another `jq`, if the output touches any other key, stop and hand-place the
block with an editor — do not accept the output.

| Setting | Why |
|---------|-----|
| `helix_mode: true` | Modal editing everywhere in Zed — selections and motions match hx, so the editor and the terminal editor agree. |
| `cursor_shape: block` + `cursor_blink: false` | Helix's block cursor, non-blinking so the caret doesn't pull the eye in a pane an agent is also writing to. |
| `theme.light` `Dayfox - opaque` / `theme.dark` `Nordfox - blurred` | System light/dark pair from the Fox family — warm, low-contrast themes that don't fight Ghostty's TokyoNight. The suffix is Zed's theme variant naming, so the pair follows the OS appearance automatically. |
| `format_on_save: modifications_if_available` | Formats on save only when the language server can format *changed* regions, so saving a large file doesn't reflow unrelated lines (keeps agent diffs reviewable). |
| `autosave: on_focus_change` | Writes a buffer when the window loses focus rather than on every keystroke or on a timer — the least intrusive policy when an agent is also touching files. |
| `focus_follows_mouse: { enabled: true }` | Clicking into a pane focuses it without a second click — matches herdr pane behaviour. |
| `preferred_line_length: 100` + `soft_wrap: "editor_width"` | `editor_width` wraps at the **editor width**; the `100` is only the preference value Zed's UI wrote and caps nothing. `soft_wrap: "bounded"` is the setting that would wrap at `min(editor width, preferred_line_length)` — i.e. enforce the 100-column cap. Also a genuine non-default choice: Zed's default `preferred_line_length` is `80`. Whether a 100-cap was intended is an open question, not a documented fact. |
| `disable_ai: true` | Zed's own AI — agent panel, threads sidebar, edit prediction, inline assistant — is off. Agents run in opencode + herdr instead. It makes the keys below **dormant** and the keymap binding inert. |
| `buffer_font_family` / `agent_buffer_font_family` = `JetBrainsMono Nerd Font Mono`, `13.0` / `15.0` | The Nerd Font from the Brewfile cask; glyphs are PUA-only (see the root README), so the font must be explicit. 1.0.1 equalized both at `15` (agent buffers had been one point smaller); the 2026-10-23 UI capture then took the *editor* buffer to `13` and left the agent buffer at `15` — the agent value is dormant with the panel. |
| `ui_font_family` / `ui_font_size` = `Source Serif 4`, `16.0` | Panel labels, tabs, and menus in a serif face, so chrome reads as a different layer from the monospace editor. Set in the Zed UI, captured back into the repo. |
| `agent_ui_font_size: 18.0` | **Dormant** with the rest of the agent surface (`agent_ui_font_family` is also `Source Serif 4`): the panel never opens while `disable_ai` is `true`, so this is a retained value, not active chrome. Captured from the UI. |
| `markdown_preview.code_font_family` = `JetBrainsMono Nerd Font Mono` | Fenced code in the markdown preview keeps the Nerd Font's glyph coverage instead of falling back to Zed's preview default. Captured from the UI. |
| `agent.default_model` (provider `opencode`, `go/deepseek-v4.1-flash`, thinking, `effort: high`) | **Dormant** — parsed and retained, but unused while `disable_ai` is `true`. It points a new thread at the same model the opencode CLI uses, so re-enabling AI needs no model hunting. |
| `agent.tool_permissions` / `agent.sandbox_permissions` | **Dormant** permission profile: default-allow tool calls with all network hosts allowed, because Zed's prompt-per-call is the slow path for an agent expected to run builds and fetch. Retained so re-enabling AI is a one-key change. |
| `context_servers.Roblox_Studio.command` | **Dormant** alongside the `agent` block: points Zed's agent at the Roblox Studio MCP binary (`/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`), the same server the opencode `mcp` block uses. **Absolute path by design** — it breaks if Studio moves; acceptable for a mac-personal-only package. |
| `auto_install_extensions` (10 IDs) | Pins *which* extensions a fresh Mac installs: `dockerfile`, `html`, `jetbrains-themes`, `just`, `latex`, `material-icon-theme`, `nvim-nightfox`, `one-dark-pro`, `toml`, `tsgo`. Schema is `{ "<id>": true \| false }`. This pins the **set**, not the versions — see *Extensions* below. |
| `search.regex: true`, `search.center_on_match: true`, scroll margins `99` | Search opens in regex mode (the `rg` habit); matches are centred and the viewport keeps a wide scroll margin so the cursor never sits at the screen edge. |

Retired in 1.1.0, with the keys they described: `agent_servers.*` (the
`opencode-v2` / `codex-acp` / `claude-acp` registry entries) and
`language_models.opencode.show_zen_models` — both only configure Zed's own
agent surface, which `disable_ai` shuts down. `agent_servers` is a *runtime*
backends map re-written by Zed's UI; keeping it invited drift for no function.

Dormant ≠ deleted: the `agent` block, `context_servers.Roblox_Studio`, and the
four `agent_ui_font_*` / `agent_buffer_font_*` keys stay in the file, so
re-enabling AI is `disable_ai: false` plus a fresh capture, not a `git revert`.

## Keymap

**The binding below is inert while `disable_ai` is `true`** — `agent::ToggleNewThreadMenu`
opens nothing when Zed's AI is off. It is retained at zero cost so it works
again the moment AI is re-enabled.

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
  (`default-macos.json:166`, context `Editor && mode == full` — full mode,
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
  (conversation history), `languages/`. Machine state, not config.
  `extensions/` is the exception worth naming precisely: its
  `extensions/installed/` listing is the **downloaded payload** (unpinned
  machine state, rebuilt on demand), while the **selection** of extensions now
  lives in config as `auto_install_extensions` (1.1.0). Config says *which*;
  this directory holds *what arrived*.
- Tracking the whole directory instead (`files/zed/` → `~/.config/zed`) was
  rejected: `dot` supports directory entries, but it would swallow the
  `prompts/` LevelDB above.

**No secrets in `settings.json`.** Tokens never belong here; the
`context_servers` entry is a command path, not a credential. Real secrets live
in `~/.env` / `~/.config/localenvs/*.local` or are persisted for the opencode
daemon (`opencode service set env …`, see the root README).

## The reconcile loop

Zed's UI **writes its config files**, so unlike every other config here, the
store copy is mutable. The loop is always: **capture → prune → re-pin** — a
bare capture is no longer sufficient, because it puts back the keys 1.1.0
retires.

```bash
dot diff zed                  # what the UI changed vs the repo — do this BEFORE apply
# 1. quit Zed (see below), then capture:
cp ~/.local/share/dot/store/zed/1.1.0/settings.json configs/zed/files/settings.json
# 2. prune — the expression from "Why these settings", verbatim:
jq 'del(.agent_servers, .language_models)
    | .auto_install_extensions = {dockerfile: true, html: true, "jetbrains-themes": true,
        just: true, latex: true, "material-icon-theme": true, "nvim-nightfox": true,
        "one-dark-pro": true, toml: true, tsgo: true}' \
   configs/zed/files/settings.json > /tmp/s && mv /tmp/s configs/zed/files/settings.json
# 3. re-pin
dot bump zed <patch|minor>     # in a worktree this only edits: hand-commit it, see below
dot apply zed
```

- **Quit Zed before `dot apply`.** A live window holds the settings it was
  started with and re-serializes that held state over the fresh store on its
  next write — which silently reverts `disable_ai: true` and puts
  `agent_servers` back. Use a graceful quit (`osascript -e 'quit app "Zed"'`),
  wait for the process to exit, apply, then relaunch (`open -a Zed`).
- **The divergence is from what Zed would serialize, not from the repo.**
  Post-apply the store *is* the repo (`dot:211-215` copies repo → store), so
  "in sync" means the store matches the repo, while the real gap is Zed's own
  in-memory model. That is a **recurring** tax, not a one-time decision: every
  settings write can resurrect the retired keys, and each resurrection is a
  re-prune — not a bug to chase.
- **The bump is load-bearing.** `dot update` re-applies only when the repo
  version is newer (`dot:599`), so a content-only edit would not reach other
  machines. This deliberately differs from the content-only convention used
  for, say, the opencode `AGENTS.md`. `dot bump` auto-commits on a normal
  checkout (`dot:664` is the commit); its guard is `[[ -d "$REPO/.git" ]]`
  (`dot:662`), which is **false inside a worktree** (`.git` is a file there),
  so a bump made from a worktree only rewrites the manifest and the commit is
  made by hand.
- **The two ordering hazards are `apply`-before-`bump` and
  `apply`-before-`capture`.** `dot apply` starts with `rm -rf` on
  `$stage = $DOT_STORE/<name>/<version>` (`dot:201-203`, `:211`): applying
  before bumping wipes the *same-version* directory, and applying before
  capturing re-points the symlink at a fresh store and orphans the mutated
  one, after which `dot diff` / `dot status` no longer see the drift at all.
- `dot edit zed` opens **only the first file** in the manifest —
  `settings.json` (`dot:492-493`). Keymap and tasks have no edit shortcut
  (`$EDITOR configs/zed/files/keymap.json`).

### Write-through, not symlink pinning (observed)

Zed canonicalizes paths before writing; the fix for "Zed deletes a symlinked
`settings.json`" ([zed#4469](https://github.com/zed-industries/zed/issues/4469))
landed in `v0.123.1-pre`, and every build this package has run carries it. A
UI edit **writes through the symlink into `store/zed/<ver>/`** — observed here
twice on 2026-10-23, not inferred:

- `~/.config/zed/settings.json` is **still a symlink** and Zed rewrote the file
  behind it. At the `00:18` write it pointed into `store/zed/1.0.0/`; after the
  1.0.1 apply (and again after 1.1.0) it points into the current version's
  directory — never at the repo.
- `dot status` reports **`modified`** — store content no longer matches the
  recorded hash. The store stops pinning anything: `dot diff`, `dot rollback`,
  and the hash all read the mutated content.
- The temp+rename branch is **not** what these builds do here. On a build that
  replaced the symlink, `dot status` would report **`drifted`** (never
  `broken` — that state means the store directory is missing).

Expected and accepted: this is the house doctrine of *drift detected, not
prevented*, applied to a config whose tool rewrites it.

- **No hot reload of a symlinked settings file**
  ([zed#38936](https://github.com/zed-industries/zed/issues/38936), closed as
  duplicate): after `dot apply zed`, a window reload may be needed for Zed to
  pick the file up — which is also why the loop now quits Zed before applying.
- **`keymap.json` is the highest-drift file of the three.** Anything done in
  the keymap editor is written straight back to `keymap.json` — check
  `dot diff zed` after remapping, not just after a settings toggle.

### Which version? Four artifacts, none interchangeable

Every behavioural claim below names the **running** version, and only `ps` /
`Zed.log` prove that. The other three answer different questions:

| Artifact | How to read it | Value (2026-10-23) |
|---|---|---|
| Cask **receipt** | `brew list --cask --versions zed` | `1.21.0` — what Homebrew installed on 2026-09-23 |
| Tap **formula** | `brew info --cask zed` | `1.25.2 (auto_updates)` — what the tap advertises; the cask self-updates past it |
| **Bundle on disk** | `defaults read /Applications/Zed.app/Contents/Info.plist CFBundleShortVersionString` | `1.25.3` — written 06:14, never launched as of the 1.1.0 apply |
| **Running process** | `ps`, `Zed.log` startup line | `1.25.2` (pid 46794, started 2026-10-22 14:53) |

So the cask receipt `1.21.0` is *not* the version that behaved: **both** drift
probes — the `00:18` write-through and the `11:40` rewrite — were `1.25.2`,
and the `1.21.0` build had not been running since 2026-09-23 (the same day it
was installed). Earlier notes crediting `1.21.0` were reading the receipt.

### The drift probes: observed

**Probe 1 — `00:18`, running Zed `1.25.2`.** Seven settings were changed
through the UI and landed in `store/zed/1.0.0/settings.json` (symlink intact,
`dot status` → `modified`). The captured diff was exactly the expected UI keys
— `ui_font_family`/`ui_font_size` (`Source Serif 4`, `16`),
`agent_ui_font_family`/`agent_ui_font_size` (`Source Serif 4`, `18`),
`markdown_preview.code_font_family` (`JetBrainsMono Nerd Font Mono`), and
`buffer_font_size`/`agent_buffer_font_size` raised `14`/`13` → `15`/`15`.
Reconciled as 1.0.1 by a verbatim copy of the store file — the loop before the
prune existed.

**Probe 2 — `11:40`, running Zed `1.25.2`.** Four UI changes, hours after
1.0.1 landed: `preferred_line_length: 100` + `soft_wrap: "editor_width"`,
`buffer_font_size` `15 → 13`, and `disable_ai: false → true`. Reconciled as
**1.1.0**, this time capture → prune → bump → apply, with Zed quit first. The
relaunch that followed was the **first run of the `1.25.3` bundle on disk** —
recorded as such, not as a `1.25.3` observation.

Still unprobed, because both probes touched only `settings.json`:

- `keymap.json` in the keymap editor — its store copy still has the
  apply-time mtime, so "the keymap editor writes `keymap.json`" is documented
  upstream but unobserved here.
- `tasks.json` acceptance — `task: spawn` has not been run against the empty
  array. `zed: open keymap file` and `task: spawn` must open without an error
  toast before "Zed accepts the scaffolds" is anything but an assumption.

```bash
readlink ~/.config/zed/settings.json     # a symlink into store/zed/<ver> — Zed wrote through
./dot diff zed                           # capture the UI edit BEFORE applying
./dot status --json | jq '.[] | select(.name=="zed") | .state'   # modified
```

## Extensions

`auto_install_extensions` records the **set** of 10 extensions a fresh Mac
should install (`{ "<id>": true }` per ID): `dockerfile`, `html`,
`jetbrains-themes`, `just`, `latex`, `material-icon-theme`, `nvim-nightfox`,
`one-dark-pro`, `toml`, `tsgo`. The list is the installed set on the source
machine, so `ls ~/Library/Application Support/Zed/extensions/installed`
and the map's keys are the same ten.

It pins *which* extensions, **not which versions**: every installed extension
auto-updates at start by default, and `auto_update_extensions: { "<id>": false }`
is the key that would pin a version. Deliberately not set — the extensions are
theme/syntax/tooling packages where tracking upstream is the point. The
downloaded payload stays machine state (see *What is deliberately not
tracked*); only the selection is config.
