# Raptor

Project picker for [Rex](https://www.superlogical.com/rex), written in Rex Lua.

Raptor lists zoxide directories in the Rex command palette. Directories with a Rex session appear first with a terminal icon.
Git worktrees and their subdirectories stay hidden.

Select a directory to open its session. By default, Raptor creates missing sessions with three tabs:
- `code`: Neovim and a shell.
- `agents`: a shell.
- `git`: lazygit.

To use other tabs, see [Custom tabs](#custom-tabs).

Session labels match directory names without case. Directories with the same name share a session match.

## Requirements

- Rex app and server.
- zoxide.
- Neovim and lazygit for the default tabs. Without them, those panes show `command not found` and keep a shell.

## Install

Add these lines to `~/.config/rex/init.lua` with your clone path and your key:

```lua
loadfile("/absolute/path/to/raptor/rex.lua")("/absolute/path/to/zoxide")
rex.bind("ctrl+a>f", "project")
```

The Rex server PATH can lack zoxide, so give its full path. Without the path, Raptor runs `zoxide` from the server PATH.

Raptor defines the `project` action and binds no key. Use any key or sequence, such as `cmd+p` or your prefix followed by `f`. Remove any other `project` action, reload Rex configuration, then press your key.

## Custom tabs

Give a function as the second argument. It gets `term(input)`, which makes a shell in the project directory and types `input` into it. It returns the tabs of a new session. Rex selects the first tab.

```lua
loadfile("/absolute/path/to/raptor/rex.lua")("/absolute/path/to/zoxide", function(term)
  return {
    { window_label = "code", layout = term("hx .\r") },
    { window_label = "shell", layout = rex.layout.vertical(0.5, term(), term()) },
  }
end)
```

Each tab is a `session.create` window. `layout` takes `term()` or the `rex.layout` functions.

