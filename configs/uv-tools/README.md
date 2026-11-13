# uv-tools

Python CLIs, installed with `uv tool install` — isolated environments, no
`sudo`, and identical on macOS and Linux. Platform-agnostic, so this is the
package config that **is** safe in the `server` profile.

`tools.txt` is a plain list, one tool per line. Add a tool and `dot apply
uv-tools` reinstalls (the `applyHash` changes, so `post_apply` re-runs).

`post_apply` runs uv through `mise exec uv@latest` when mise is installed
(macOS profiles, where mise replaces the Homebrew uv), so it works from a
non-interactive shell before mise is activated. Without mise (the `server`
profile) it falls back to `uv` on `PATH`.
