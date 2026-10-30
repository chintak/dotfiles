# shared

Agent config written **once** and installed into every coding-agent
package (`opencode`, `claude`). Nothing here is applied directly. Each
package pulls it in, and its store copy holds real files, so either package
installs alone on a new machine.

| Source | How packages use it |
|--------|---------------------|
| `AGENTS.md` | git symlink `configs/<pkg>/files/AGENTS.md → ../../../shared/AGENTS.md`. OpenCode reads `~/.config/opencode/AGENTS.md`. Claude Code reads `~/.claude/CLAUDE.md`, which is just `@AGENTS.md`. Tool-specific notes live in labelled sub-bullets, not in separate files. |
| `skills/` | git symlink `configs/<pkg>/files/skills → ../../../shared/skills`. OpenCode links the whole dir. Claude links one `~/.claude/skills/<name>` per skill, because other tools also write into that dir. **Adding a skill means adding a `file = skills/<name>\|~/.claude/skills/<name>` line to `configs/claude/manifest`.** |
| `mcp.json` | tool-neutral server list, rendered by `render-mcp.py` into the generated block of `configs/opencode/files/opencode.jsonc` and into `configs/claude/files/mcp.json`. Commit the rendered output. |

## mcp.json fields

- `command`: stdio argv (OpenCode `local`, Claude `stdio`).
- `url`: remote server (OpenCode `remote`, Claude `http`).
- `bearer`: the env var holding an `Authorization: Bearer` token.
  - OpenCode: `oauth: false` + `{env:VAR}`, resolved by the daemon.
  - Claude: a `headersHelper` running `mcp-bearer.sh VAR`. It tries env →
    keychain `dot-mcp-VAR` → the OpenCode daemon env, if installed.
- `env`: `{VAR: VAR}` passthrough. OpenCode only for now.
- `only`: limit a server to some targets. `huggingface` and `exa` are
  `opencode`-only, because Claude Code already gets them as claude.ai
  connectors.
- `comment`: rendered as a `//` comment above the OpenCode entry.

## Workflow

```bash
$EDITOR shared/mcp.json && shared/render-mcp.py   # or AGENTS.md / skills/
zsh test/shared-sync.zsh                          # links, skill list, render freshness
dot bump opencode minor && dot bump claude minor  # both packages ship the change
dot apply opencode claude
```
