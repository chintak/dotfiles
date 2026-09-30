-- yazi init.lua — plugin setup.
-- Only git needs setup here: smart-enter's default (hovered-only open,
-- consistent with `Enter`/`e` in keymap.toml) is what we want, so no
-- smart-enter setup call. vcs-files, diff, toggle-pane, jump-to-char
-- need no setup (keybindings only, see keymap.toml).
require("git"):setup {
	-- Order of status signs showing in the linemode
	order = 1500,
}
