-- Rex — key bindings that mirror the Ghostty + herdr setup.
-- Docs: https://www.superlogical.com/rex/docs/customize/keyboard-shortcuts
--
-- In Ghostty, herdr owns tabs/panes/workspaces and Ghostty forwards its
-- chords to it. Rex is its own multiplexer, so the same chords bind to
-- Rex's native actions instead: herdr tab -> Rex tab, pane -> pane,
-- workspace -> session. Only herdr's direct chords are carried over; the
-- ctrl+b prefix stays free for tmux running inside a pane.
-- Reload after editing: rex config reload

-- ── tabs ───────────────────────────────────────────────────────────────
for _, k in ipairs{ "shift+alt+left", "alt+[", "cmd+shift+[", "ctrl+alt+[" } do
  rex.bind(k, "client.tab.previous")
end
for _, k in ipairs{ "shift+alt+right", "alt+]", "cmd+shift+]", "ctrl+alt+]" } do
  rex.bind(k, "client.tab.next")
end
rex.bind("alt+n", "client.tab.new")
rex.bind("cmd+t", "client.tab.new")
rex.bind("alt+r", "client.tab.rename")
rex.bind("alt+w", "client.tab.close")
rex.bind("cmd+w", "client.tab.close")
rex.bind("alt+shift+[", "client.tab.move.backward")
rex.bind("alt+shift+]", "client.tab.move.forward")
for i = 1, 9 do
  rex.bind("alt+" .. i, "client.tab.goto", { index = i })
end

-- ── panes ──────────────────────────────────────────────────────────────
-- Focus: cmd+alt+arrows, ctrl+alt+hjkl, shift+alt+j/k.
local hjkl = { left = "h", down = "j", up = "k", right = "l" }
for dir, letter in pairs(hjkl) do
  rex.bind("cmd+alt+" .. dir, "pane.focus", { direction = dir })
  rex.bind("ctrl+alt+" .. letter, "pane.focus", { direction = dir })
  -- Resize: cmd+ctrl+arrows, ctrl+shift+alt+hjkl.
  rex.bind("cmd+ctrl+" .. dir, "pane.resize", { direction = dir })
  rex.bind("ctrl+shift+alt+" .. letter, "pane.resize", { direction = dir })
end
rex.bind("shift+alt+k", "pane.focus", { direction = "up" })
rex.bind("shift+alt+j", "pane.focus", { direction = "down" })

-- Split: herdr's alt+d / alt+shift+d, plus Ghostty's native cmd+d / cmd+shift+d.
rex.bind("alt+d", "pane.split", { direction = "right" })
rex.bind("cmd+d", "pane.split", { direction = "right" })
rex.bind("alt+shift+d", "pane.split", { direction = "down" })
rex.bind("cmd+shift+d", "pane.split", { direction = "down" })

-- Cycle: herdr's alt+u / alt+i, plus Ghostty's native cmd+] / cmd+[.
rex.bind("alt+u", "pane.focus_next")
rex.bind("cmd+]", "pane.focus_next")
rex.bind("alt+i", "pane.focus_previous")
rex.bind("cmd+[", "pane.focus_previous")

rex.bind("alt+shift+enter", "pane.zoom")
rex.bind("cmd+shift+enter", "pane.zoom")

-- ── workspaces -> sessions ─────────────────────────────────────────────
rex.bind("shift+alt+n", "session.new")
rex.bind("cmd+n", "session.new")
rex.bind("shift+alt+up", "session.previous")
rex.bind("shift+alt+down", "session.next")
rex.bind("shift+alt+r", "session.rename")
rex.bind("shift+alt+w", "session.close")
rex.bind("cmd+shift+w", "session.close")
rex.bind("cmd+p", "session.switch")

-- cmd+1..9 jumps to the Nth session, in sidebar (creation) order.
rex.action{
  name  = "goto_session",
  title = "Go to Session by Number",
  args  = { index = "integer" },
  run   = function(ctx, args)
    local res, err = rex.call("session.list")
    if err ~= nil then error(err, 0) end
    local s = (res.sessions or res)[args.index]
    if s == nil then return end
    rex.client.queue("session.select", { session_id = s.session_id or s.id })
  end,
}
for i = 1, 9 do
  rex.bind("cmd+" .. i, "goto_session", { index = i })
end

-- ── word/line navigation -> Helix ──────────────────────────────────────
-- Same intent as the Ghostty overrides: send real alt+arrows and
-- Home/End instead of readline bytes, which fight Helix's insert mode.
rex.bind("alt+left", "pane.send_key", { key = "alt+left" })
rex.bind("alt+right", "pane.send_key", { key = "alt+right" })
rex.bind("cmd+left", "pane.send_key", { key = "home" })
rex.bind("cmd+right", "pane.send_key", { key = "end" })
