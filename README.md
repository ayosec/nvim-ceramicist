<!-- panvimdoc-ignore-start -->

<h1 align="center">Ceramicist</h1>

<div align="center">

**[Installation](#installation) | [Usage](#usage) | [Configuration](#configuration)**

</div>

---

https://github.com/user-attachments/assets/96224d1b-654f-4767-881b-3a2c857db43a

---

<!-- panvimdoc-ignore-end -->

## Introduction

<!-- website-start -->

Ceramicist is Neovim plugin to execute shell commands (like `:!`) and display
their output in a dedicated window. It is similar to the [terminal] available in
Neovim, but with some features intended to make it more convenient to use when
you don't need a full shell.

The main features are:

* The shell command to run is written directly in Neovim's
  [command line][h.Command-line].

* Multiple commands can be appended to a single session.

* The terminal window automatically starts Terminal mode when a shell command is
  run, and returns to Normal mode when it finishes.

* A header is written to show which shell command is executed.

* A footer is written to show the exit status and the duration of the command.

* The [statusline][h.status-line] shows information about the session.

[h.Command-line]: https://neovim.io/doc/user/cmdline/
[h.status-line]: https://neovim.io/doc/user/windows/#status-line
[terminal]: https://neovim.io/doc/user/terminal/#terminal

<!-- panvimdoc-ignore-start -->

## Installation

Ceramicist can be installed with any package manager for Neovim, like
[`vim.pack`](https://neovim.io/doc/user/pack/#_plugin-manager):

```lua
vim.pack.add { "https://github.com/ayosec/nvim-ceramicist" }

require("ceramicist").setup({})
```

<!-- panvimdoc-ignore-end -->

## Usage

The `setup()` function creates an instance of Ceramicist.

```lua
require("ceramicist").setup({})
```

This instance is accessible through the user-command defined in the `setup()`
options. By default, the user-command is `:Ceramicist`:

```vim
:Ceramicist ./scripts/something
```

The arguments of the user-command specify the shell command to run, like `:!`.

If there is another job running when a new one is executed, the previous job is
interrupted before starting the new one.

To define a different command name (for example, `:C`):

```lua
require("ceramicist").setup {
    user_command = { name = "C" }
}
```

Then:

```vim
:C make test
```

### Repeating Commands

If the user-command is executed with no arguments it repeats the last shell
command, like `:!!`.


```vim
:Ceramicist make test

:Ceramicist             " Repeat 'make test'
```

You can also use the `rerun()` function, available in the buffer variable
`b:ceramicist_session`, to repeat it.

The next example uses an autocommand to trigger a rerun when <kbd>C-R</kbd> is
pressed on a window for a Ceramicist session:

```lua
vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/SessionCreated",
    callback = function(args)
        local map_opts = { buf = args.data.buffer }

        vim.keymap.set(
            "n", "<C-R>",
            function() vim.b.ceramicist_session().rerun() end,
            map_opts
        )
    end
})
```

### Watch Mode

The `:CeramicistToggleWatch` user-command can enable or disable the Watch mode
in a session. The user-command changes only the session in the current buffer.
To enable Watch mode in multiple sessions, execute it in each one.

When Watch mode is enabled, the last shell command in the session is repeated
after saving changes on any buffer. See `:h BufWritePost`.

### Content Reset

If the user-command is executed with the `!` modifier (see `:h :_!`)
the output from previous jobs is removed before running a new one:

```vim
:Ceramicist scripts/tests       " The output is added to the session.

:Ceramicist! scripts/tests      " Reset session before running the job.
```

### Multiple Sessions

Multiple sessions of the same instance can be created by adding a number
to the user-command, either before or after the name:

```vim
:Ceramicist scripts/something       " Default session.

:2Ceramicist scripts/other          " Session 2

:Ceramicist2 scripts/other          " Session 2
```

The number is the session id. Its default value depends on the context where the
user-command is executed:

- If the current buffer is a Ceramicist session, use its id.
- If there is at least one session, use the smallest id.
- If there are no sessions, defaults to `1`.

### Multiple Instances

Multiple instances of Ceramicist can be created with different calls to
`setup()`, each one with its own user-command name.

The next example defines an instance on `:C` with the default configuration, and
another instance on `:M` that executes `make(1)` instead of a shell expression.
It also provides a custom completion list for `:M`:

```lua
require("ceramicist").setup {
    user_command = { name = "C" }
}

require("ceramicist").setup {
    user_command = {
        name = "M",
        complete = function()
            return { "all", "fmt", "test" }
        end,
    },

    job_command = function(cmdline)
        return { "make", cmdline }
    end,
}
```

For more details on the `user_command.complete` field, see
`:h :command-complete` and `:h :command-completion-customlist`.

### Window Placement

By default, the window for the session is open in a horizontal split at the
bottom of the current tab. The modifiers `:vertical`, `:tab`, `:topleft`, etc,
can be used to change the placement of the new window:

* `:topleft Ceramicist ...` open a horizontal split at the top.
* `:vertical Ceramicist ...` open a vertical split to the right.
* `:vertical topleft Ceramicist ...` open a vertical split to the left.
* `:tab Ceramicist ...` open the session in a new tab.

### Deleting Sessions

A session can be deleted with `:bdelete!` (or just `:bd!`). When it is deleted,
its state (the output from previous jobs, the last shell command, etc) is lost.

If there is a running job when the buffer is deleted, the job is interrupted.

The session will be recreated the next time the user-command is executed.

### Listing Sessions

The function `list_sessions` returns an iterator to get all active sessions.
These objects can be used to add extra functionality to manage the sessions.

For example, to add a `:DeleteCeramicistSessions` user-command to delete all
idle (i.e. without a running job) sessions:

```lua
vim.api.nvim_create_user_command(
    "DeleteCeramicistSessions",
    function()
        for session in require("ceramicist").list_sessions() do
            if not session.is_running() then
                vim.cmd.bdelete { session.buffer, bang = true }
            end
        end
    end,
    { desc = "Delete idle Ceramicist sessions" }
)
```

## Configuration

The default configuration provided by Ceramicist is very basic, since it is
expected that users adjust it to their own preferences.

<!-- panvimdoc-ignore-start -->

See [`config.lua`](./lua/ceramicist/config.lua) for a reference of all available
options.

The configuration is defined as the argument of the `setup()` function. Each
call to `setup()` creates a new Ceramicist instance. There is no global state,
so each instance has its own configuration.

<!-- panvimdoc-ignore-end -->

<!-- panvimdoc-include-comment
The default configuration can be used as a reference of all available options:
-->

<!-- panvimdoc-include-config -->

### Header and Footer

The fields `output.header` and `output.footer` can define functions that are
used to render the header before running a job, and the footer after it is
finished.

Both functions must return a list of `{ text, highlight }` pairs, like the
`virt_text` field of `:h nvim_buf_set_extmark`.

`header()` receives a single argument, a string with the command line used to
run the job.

`footer()` receives the exit code and the duration in nanoseconds. The exit code
can be either an integer, or a string with the name of the signal that stopped
the process.

### Status Line

The field `statusline` defines a string to be used as the statusline of the
sessions of the instance.

The buffer variable `b:ceramicist_statusline` is a function to provide a short
summary of the status of the session (the PID of the running job, if Watch mode
is enabled, the full command line, etc).

If `statusline` is `false`, the statusline is not modified.

### Autocommands

Extra configuration options can be set by using autocommands:

* `Ceramicist/SessionCreated`
* `Ceramicist/JobFinished`
* `Ceramicist/JobStarted`

In the `data` field, `SessionCreated` receives the buffer number, the window id,
and the instance of the session.

For `JobStarted` and `JobFinished`, they also receive the command line to run
the job.

The next example uses `SessionCreated` to add 2 key mappings (<kbd>C-R</kbd> to
repeat the last command, and <kbd>C-A</kbd> to toggle Watch mode).

```lua
vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/SessionCreated",
    callback = function(args)
        local map_opts = { buf = args.data.buffer }

        -- <C-A> toggle watch
        vim.keymap.set("n", "<C-A>", "<Cmd>CeramicistToggleWatch<CR>", map_opts)

        -- <C-R> rerun
        vim.keymap.set(
            "n", "<C-R>",
            function() vim.b.ceramicist_session().rerun() end,
            map_opts
        )
    end
})
```

The next example uses [`matchadd()`][h.matchadd()] to highlight some patterns when the
shell command starts with `scripts/`.

[h.matchadd()]: https://neovim.io/doc/user/vimfn/#matchadd()

```lua
vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/JobStarted",
    callback = function(args)
        local buffer = args.data.buffer
        local window = args.data.window
        local cmdline = args.data.cmdline

        -- Use a buffer variable to track if the matchadd() is done.
        if vim.b[buffer].has_matchadd then return end

        if vim.startswith(cmdline, "scripts/") then
            vim.b[buffer].has_matchadd = true
            vim.fn.matchadd("DiagnosticInfo", "^INFO", 0, -1, { window = window })
            vim.fn.matchadd("DiagnosticError", "^ERROR", 0, -1, { window = window })
        end
    end
})
```


### Example

The configuration example below:

- Creates highlight groups to replace the default colors, and add new ones for
  the added components in the header and the footer.
- Includes a timestamp in the header.
- Uses custom highlights for the different components of the footer.
- Add some key mappings to the session's buffer.

<!-- demo-config -->

```lua
vim.api.nvim_set_hl(0, "CeramicistNormal", { bg = "#001429" })

vim.api.nvim_set_hl(0, "CeramicistHeader", { bg = "#002E5C" })
vim.api.nvim_set_hl(0, "Ceramicist.Time", { fg = "#7777FF" })

vim.api.nvim_set_hl(0, "CeramicistFooterFail", { bg = "#652131" })
vim.api.nvim_set_hl(0, "CeramicistFooterSuccess", { bg = "#21653F" })

vim.api.nvim_set_hl(0, "Ceramicist.Success.Duration", { bg = "#329A5F"  })
vim.api.nvim_set_hl(0, "Ceramicist.Fail.Duration", { bg = "#9A324A"  })
vim.api.nvim_set_hl(0, "Ceramicist.Fail.Code", { bg = "#732638"  })
vim.api.nvim_set_hl(0, "Ceramicist.Fail.Signal", { bg = "#73264D"  })

vim.api.nvim_set_hl(0, "CeramicistStatusLineWatch", { bg = "#004D4D" })
vim.api.nvim_set_hl(0, "CeramicistStatusLineRunning", { bg = "#702000" })


local utils = require("ceramicist.utils")

local context = require("ceramicist").setup({
    user_command = { name = "C" },

    output = {
        gap = 3,

        header = function(cmdline)
            return {
                { vim.fn.strftime(" %H:%M:%S  "), "Ceramicist.Time" },
                { utils.escape_control_chars(cmdline), "" },
            }
        end,

        footer = function(exit, duration)
            local fd = " " .. utils.format_duration(duration) .. " "
            if exit == 0 then
                return { { "   ", "" }, { fd, "Ceramicist.Success.Duration" } }
            end

            -- Failed
            local status
            if type(exit) == "number" then
                status = { " $! = " .. exit .. " ", "Ceramicist.Fail.Code" }
            else
                status = { " " .. exit .. " ", "Ceramicist.Fail.Signal" }
            end

            local sep = { "   ", "" }
            return {  sep, status, sep, { fd, "Ceramicist.Fail.Duration" } }
        end,
    },
})


vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/SessionCreated",
    callback = function(args)
        local map_opts = { buf = args.data.buffer }

        -- <C-A> toggle watch
        vim.keymap.set(
            "n", "<C-A>",
            "<Cmd>CeramicistToggleWatch<CR>",
            map_opts
        )

        -- <C-R> rerun
        vim.keymap.set(
            "n", "<C-R>",
            function() vim.b.ceramicist_session().rerun() end,
            map_opts
        )
    end
})
```

<!-- panvimdoc-ignore-start -->

## Alternatives

There are many plugins providing a similar functionality to Ceramicist. This is a non-exhaustive list of alternatives:

* [command-runner.nvim](https://github.com/marzeq/command-runner.nvim)
* [como.nvim](https://github.com/JordenHuang/como.nvim)
* [compile-mode.nvim](https://github.com/ring0-rootkit/compile-mode.nvim)
* [erun.nvim](https://github.com/kotsmile/erun.nvim)
* [overseer.nvim](https://github.com/stevearc/overseer.nvim)
* [taskrun.nvim](https://github.com/yutkat/taskrun.nvim)

<!-- panvimdoc-ignore-end -->
