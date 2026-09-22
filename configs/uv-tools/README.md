# uv-tools

Python CLIs, installed with `uv tool install` — isolated environments, no
`sudo`, and identical on macOS and Linux. Platform-agnostic, so this is the
package config that **is** safe in the `server` profile.

`tools.txt` is a plain list, one tool per line. Add a tool and `dot apply
uv-tools` reinstalls (the `applyHash` changes, so `post_apply` re-runs).
