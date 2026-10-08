-- yazi init.lua — plugin setup.
-- git: status sign order in the linemode. vcs-files, diff, toggle-pane,
-- jump-to-char, smart-enter need no setup (keybindings only, see keymap.toml;
-- smart-enter's hovered-only default matches the Enter/e convention).
require("git"):setup {
	-- Order of status signs showing in the linemode
	order = 1500,
}

-- duckdb: setup is required even with defaults — it initializes the plugin's
-- sync state (mode, column width, scroll position) that peek/entry rely on.
require("duckdb"):setup {}

-- mux: cycles csv/tsv/json previews through duckdb → rich-preview → code on `M`.
-- mux resolves each name via require() to the plugin dir, so `rich-preview`
-- loads rich-preview.yazi directly; `duckdb` resolves to duckdb.yazi and `code`
-- is yazi's builtin previewer.
require("mux"):setup {
	notify_on_switch = true,
}
