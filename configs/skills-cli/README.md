# skills-cli

Installs the `skills-cli` binary to `~/.local/bin`. It copies markdown skills
from this repo's `skills/` directory into a project's `.cursor/`, `.claude/`, or
`.codex/` directory, so every agent gets the same instructions.

Because `dot` installs from a **store**, the binary's `__file__` no longer points
at the repo. The script resolves the repo from `$DOT_REPO` →
`~/.local/share/dot/repo` → `~/.config/dot/repo` before falling back to its own
location.

```bash
skills-cli skills list
skills-cli skills install ship
```
