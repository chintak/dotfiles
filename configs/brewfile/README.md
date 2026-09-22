# brewfile

macOS-only package manifest, applied by `post_apply = brew bundle`.

**Why it is not in the `server` profile:** it contains **casks** (Ghostty, the
JetBrains Mono Nerd Font). Casks don't exist on Linux, and a headless GPU box has
no use for a terminal emulator or a font. On a server it would be slow, partly
broken, and unwanted.

Check state with `brew bundle check --file ~/.config/dot/Brewfile`.
