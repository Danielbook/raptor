-- Raptor: project picker for Rex. Load this file from init.lua with
-- loadfile(path)(zoxide, windows). The Rex server PATH can lack zoxide, so
-- give its full path. windows is an optional function(term) that returns
-- the tabs of a new session. term(input) makes a shell in the project.
local zoxide, windows = ...
zoxide = zoxide or "zoxide"
-- Tabs: code (nvim + shell), agents and git.
windows = windows or function(term)
  return {
    { window_label = "code", layout = rex.layout.horizontal(0.5, term("nvim\r"), term()) },
    { window_label = "agents", layout = term() },
    { window_label = "git", layout = term("lazygit\r") },
  }
end
local home = os.getenv("HOME")

-- The nearest .git of a Git worktree is a file, not a directory. A read
-- from a directory gives nil.
local function in_worktree(d)
  while d ~= "" do
    local f = io.open(d .. "/.git")
    if f then
      local file = f:read(1) ~= nil
      f:close()
      return file
    end
    d = d:match("^(.*)/[^/]*$")
  end
  return false
end

rex.action{
  name = "project",
  title = "Raptor",
  run = function(ctx)
    -- Session labels are directory names, compared without case.
    -- ponytail: two directories with the same name share one session.
    local open = {}
    for _, s in ipairs(rex.call("session.list").sessions or {}) do
      open[s.label:lower()] = open[s.label:lower()] or s.session_id
    end

    local r = assert(rex.exec({ zoxide, "query", "-l" }))
    -- Directories with a session go first. Each group keeps the zoxide order.
    local first, rest = {}, {}
    for d in r.stdout:gmatch("[^\n]+") do
      if not in_worktree(d) then
        local name = d:match("[^/]+$") or d
        -- The palette is narrow, so the name goes first and the path below it.
        local item = { id = d, title = name, subtitle = (d:gsub("^" .. home:gsub("%p", "%%%0"), "~")) }
        local id = open[name:lower()]
        if id then
          item.icon = "terminal"
          -- Pick items have no color field. Emoji keep their own color.
          item.detail = id == ctx.session_id and "🔵 current" or "🟢 open"
          table.insert(first, item)
        else
          item.icon = "folder"
          table.insert(rest, item)
        end
      end
    end
    -- rex.ui.pick shows at most 2,000 items.
    for _, item in ipairs(rest) do
      if #first == 2000 then break end
      table.insert(first, item)
    end

    local dir = rex.ui.pick{
      title = "🦖 Raptor",
      placeholder = "Open project · " .. os.date("%A, %B %d"),
      items = first,
    }
    if dir == nil then return end

    local name = dir:match("[^/]+$") or dir
    local id, window = open[name:lower()], nil
    if not id then
      local function term(input)
        return rex.layout.block{
          flavor = "com.superlogical.terminal.shell",
          options = { cwd = dir, initial_input = input },
        }
      end
      local s = assert(rex.call("session.create", { label = name, initial_windows = windows(term) }))
      -- The last window becomes active, so select the first.
      id, window = s.session_id, s.initial_windows[1].window_id
    end

    rex.client.queue("session.select", { session_id = id, window_id = window })
  end,
}
