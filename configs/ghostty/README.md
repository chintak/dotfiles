# ghostty

The renderer only — herdr owns panes. Two non-obvious jobs:

1. **Hand its chords to herdr.** Ghostty's native split/tab shortcuts are
   `unbind`-ed so herdr receives them. In 1.3.x the native Split menu can win
   over `unbind`, so the split chords are emitted as explicit Kitty keyboard
   protocol CSI-u sequences (`performable:super+d=text:…`).
2. **Comfort**: TokyoNight Night, 100 MB scrollback (agents emit a lot), `option-as-alt`
   so Alt chords reach herdr, and a global quake terminal on `cmd+shift+`` `.

`copy-on-select = false` is deliberate — it's broken on macOS 26 in 1.3.x.

**Gotcha:** Ghostty reads *two* paths on macOS. A leftover file at
`~/Library/Application Support/com.mitchellh.ghostty/config` silently overrides
`~/.config/ghostty/config`. `dot init` moves it aside. Verify with
`ghostty +show-config | grep -E 'font-family|theme'`.
