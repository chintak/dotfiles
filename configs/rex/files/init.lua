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

-- ── agents ─────────────────────────────────────────────────────────────
-- herdr's agent jumping, across every session: alt+tab / shift+alt+tab
-- cycle, shift+alt+1..9 jump to the Nth, cmd+shift+a opens the switcher.
-- A pane is an agent when a known agent reports its status (OSC 7501:
-- Claude Code and opencode natively, pi via pi-rex-status.ts) or
-- runs as the pane's foreground program.
local TERM = "com.superlogical.terminal"
local AGENT_APPS = { ["claude-code"] = true, pi = true, opencode = true, codex = true }
local AGENT_PROGRAMS = { claude = "claude-code", pi = "pi", opencode = "opencode", codex = "codex" }
local URGENCY = { blocked = 1, error = 2, done = 3, working = 4, idle = 5 }

local function basename(p)
  return type(p) == "string" and p:match("([^/]+)$") or nil
end

-- The agent in one pane, or nil. A program reporting several records
-- (root + workers) is summarized by its most urgent one.
local function describe_agent(sid, bid)
  local where = { session_id = sid, block_id = bid }
  local status = rex.block.call(TERM, "program_status", where)
  local rec
  for _, r in ipairs(status and status.records or {}) do
    if AGENT_APPS[r.effective_app or r.app]
      and (rec == nil or (URGENCY[r.state] or 9) < (URGENCY[rec.state] or 9)) then
      rec = r
    end
  end
  local proc = rex.block.call(TERM, "process", where)
  local fg = proc and proc.foreground or {}
  local app = rec and (rec.effective_app or rec.app)
  if app == nil then
    for _, name in ipairs{ basename(fg.argv0), fg.name, basename(fg.invoked_path) } do
      if AGENT_PROGRAMS[name] then app = AGENT_PROGRAMS[name]; break end
    end
  end
  if app == nil then return nil end
  local title = rex.block.call(TERM, "title", where)
  return {
    app = app,
    state = rec and rec.state or "unknown",
    kind = rec and rec.kind,
    msg = rec and rec.msg,
    updated_at = rec and rec.updated_at,
    title = title and title.title or "",
    cwd = fg.cwd,
  }
end

-- Every agent pane, in session order, then tab order, then layout order.
local function list_agents()
  local res, err = rex.call("session.list")
  if err ~= nil then error(err, 0) end
  local agents = {}
  for _, s in ipairs(res.sessions) do
    local att = rex.call("session.attach", { session_id = s.session_id })
    for tab, w in ipairs(att and att.view and att.view.windows or {}) do
      for _, layer in ipairs(w.layers or {}) do
        for _, b in ipairs(layer.blocks or {}) do
          local a = b.creator_name == TERM and describe_agent(s.session_id, b.block_id)
          if a then
            a.session_id, a.session = s.session_id, s.label
            a.window_id, a.tab, a.block_id = w.window_id, tab, b.block_id
            agents[#agents + 1] = a
          end
        end
      end
    end
  end
  return agents
end

-- From a key, the app runs the action and the queued select shows the pane.
-- The switcher runs it through the CLI, whose queue no window follows, so it
-- passes the app's client and that client is asked to select instead.
local function goto_agent(a, client_id)
  rex.call("session.attach", { session_id = a.session_id })
  rex.session.focus_block{ session_id = a.session_id, block_id = a.block_id }
  local select = { session_id = a.session_id, window_id = a.window_id }
  if client_id then
    local _, err = rex.call("client.perform", { client_id = client_id, action = "session.select", args = select })
    if err ~= nil then error(err, 0) end
  else
    rex.client.queue("session.select", select)
  end
end

-- Step through the agents from the focused pane, wrapping around.
local function step_agent(ctx, delta)
  local agents = list_agents()
  if #agents == 0 then return end
  local at
  for i, a in ipairs(agents) do
    if a.block_id == ctx.block_id then at = i; break end
  end
  if at == nil then at = delta > 0 and 0 or 1 end
  goto_agent(agents[(at - 1 + delta) % #agents + 1])
end

rex.action{
  name = "agents", title = "List Agents", category = "Agents",
  run = function() return list_agents() end,
}
rex.action{
  name = "goto_agent", title = "Go to Agent Pane", category = "Agents",
  args = { session_id = "string", window_id = "string", block_id = "string", client_id = "string?" },
  run = function(_, args) goto_agent(args, args.client_id) end,
}
rex.action{
  name = "next_agent", title = "Next Agent", category = "Agents",
  run = function(ctx) step_agent(ctx, 1) end,
}
rex.action{
  name = "previous_agent", title = "Previous Agent", category = "Agents",
  run = function(ctx) step_agent(ctx, -1) end,
}
rex.action{
  name = "focus_agent", title = "Go to Agent by Number", category = "Agents",
  args = { index = "integer" },
  run = function(_, args)
    local a = list_agents()[args.index]
    if a then goto_agent(a) end
  end,
}
rex.action{
  name = "agent_switcher", title = "Agent Switcher…", category = "Agents",
  keywords = "agents claude pi opencode codex switch jump",
  run = function(ctx)
    -- Jumps select in the window the switcher was opened from. Opened by a
    -- script or the CLI, that's the session's app window instead.
    local client_id = ctx.client_id
    local me = rex.call("client.inspect", { client_id = client_id })
    if not (me and me.client and me.client.info and me.client.info.kind == "app") then
      local att = rex.call("session.list_clients", { session_id = ctx.session_id })
      for _, c in ipairs(att and att.clients or {}) do
        if c.info and c.info.kind == "app" then client_id = c.client_id; break end
      end
    end
    local view = rex.session.view{}
    local _, err = rex.session.new_layer{
      window_id = view and view.active_window_id,
      bounds = { 0.1, 0.08, 0.8, 0.84 },
      focus = true,
      layout = rex.layout.block{
        flavor = TERM .. ".shell",
        options = { command = { os.getenv("HOME") .. "/.config/dot/rex-agents", "--client", client_id } },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("alt+tab", "next_agent")
rex.bind("shift+alt+tab", "previous_agent")
for i = 1, 9 do
  rex.bind("shift+alt+" .. i, "focus_agent", { index = i })
end
rex.bind("cmd+shift+a", "agent_switcher")

-- ── word/line navigation -> Helix ──────────────────────────────────────
-- Same intent as the Ghostty overrides: send real alt+arrows and
-- Home/End instead of readline bytes, which fight Helix's insert mode.
rex.bind("alt+left", "pane.send_key", { key = "alt+left" })
rex.bind("alt+right", "pane.send_key", { key = "alt+right" })
rex.bind("cmd+left", "pane.send_key", { key = "home" })
rex.bind("cmd+right", "pane.send_key", { key = "end" })
