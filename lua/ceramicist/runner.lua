local M = {}


--- @param config ceramicist.Config
--- @param session ceramicist.Session
--- @param cmdline string
local function emit_header(config, session, cmdline)
    if session.term_channel_id == nil then return end

    if session.last_job ~= nil then
        session.add_empty_lines(config.output.gap)
    end

    session.add_extmark {
        hl_mode = "combine",
        line_hl_group = config.highlight_name_prefix .. "Header",
        virt_text_pos = "overlay",
        virt_text = config.output.header(cmdline),
    }

    -- Send OSC 133 sequence to allow using [[ and ]] mappings.
    vim.api.nvim_chan_send(session.term_channel_id, "\x1B]133;A\x07\r\n")

    session.add_empty_lines(config.output.padding)
end

--- @param context ceramicist.Context
--- @param cwd string|nil
--- @param session ceramicist.Session
--- @param cmdline string
--- @param replace boolean
--- @param grab_window_focus boolean
--- @param win_opts "tab"|vim.api.keyset.win_config
function M.run(context, cwd, session, cmdline, replace, grab_window_focus, win_opts)
    local config = context.config

    if cwd == nil then
        cwd = vim.uv.cwd() or "."
    end

    -- Interrupt the previous job if it is still running.
    if session.running_job_id then
        vim.fn.jobstop(session.running_job_id)

        -- Wait up to 500ms to stop the job. This is just to
        -- avoid mixing the stop/start messages in the output,
        -- so the footer of the stopped job appears before
        -- the header of the new one.
        vim.wait(500, function() return session.running_job_id == nil end, 25)
    end

    -- Reuse a window if the buffer is already visible.
    local window = vim.fn.bufwinid(session.buffer)
    if window == -1 then
        if not grab_window_focus then
            -- Skip run if the session is not in a visible window.
            return
        elseif win_opts == "tab" then
            local tab = vim.api.nvim_open_tabpage(session.buffer, true, {})
            window = vim.api.nvim_tabpage_get_win(tab)
        elseif type(win_opts) == "table" then
            window = vim.api.nvim_open_win(session.buffer, true, win_opts)
        else
            assert(false, "Unreachable")
            return
        end

        local winhl = vim.wo[window].winhighlight
        if winhl ~= "" then winhl = winhl .. "," end
        vim.wo[window][0].winhighlight = winhl .. "Normal:" .. context.hl("Normal")

        local stl = context.config.statusline
        if stl then
            vim.wo[window][0].statusline = stl
        end
    end

    -- The band modifier clears the content of the terminal before
    -- executing the job.
    if replace and session.term_channel_id ~= nil then
        session.clear()
    end

    if session.term_channel_id == nil then
        -- Initialize the terminal after creating the window.
        session.term_channel_id = vim.api.nvim_open_term(session.buffer, {
            on_input = function (_, _, _, data)
                if session.running_job_id then
                    vim.api.nvim_chan_send(session.running_job_id, data)
                else
                    -- <C-c> or <Esc> exit TERMINAL mode.
                    if data == "\3" or data == "\x1b" then
                        vim.cmd.stopinsert()
                    end
                end
            end
        })

        vim.api.nvim_exec_autocmds("User", {
            pattern = "Ceramicist/SessionCreated",
            data = {
                buffer = session.buffer,
                context = function() return context end,
                session = function() return session end,
            }
        })
    end

    assert(session.term_channel_id ~= 0, "Missing terminal channel")
    assert(vim.api.nvim_win_is_valid(window), "Invalid window ID")

    emit_header(config, session, cmdline)

    if grab_window_focus then
        -- Focus the window and start TERMINAL mode, so users can interact
        -- with the job, or interrupting it with <C-c>, immediately.
        vim.fn.win_gotoid(window)
        vim.cmd.startinsert()
    else
        -- Do not change the focused window, but ensure that cursor
        -- is at the end, so the output from the job updates scroll.
        local lines = vim.api.nvim_buf_line_count(session.buffer)
        vim.api.nvim_win_set_cursor(window, { lines, 0 })
    end

    vim.api.nvim_buf_set_name(session.buffer, string.format(
        "[#%s] %s",
        session.id,
        #cmdline > 16 and string.sub(cmdline, 0, 16) .. "…" or cmdline
    ))

    local job_id = -1
    local start_time = vim.uv.hrtime()

    vim.bo[session.buffer].busy = 1

    session.last_job = {
        cmdline = cmdline,
        cwd = cwd,
    }

    -- If the program running in the job tries to change the cursor
    -- position (CUP), or to erase the display (DECSED), the window
    -- adds empty lines to push the current output to the scrollback,
    -- only once per job.
    local win_cleared = false

    job_id = vim.fn.jobstart(
        config.job_command(cmdline),
        {
            pty = true,
            width = vim.fn.winwidth(window),
            height = vim.fn.winheight(window),
            cwd = cwd,

            on_exit = function(_, exit_code)
                local duration = vim.uv.hrtime() - start_time
                local chan_id = session.term_channel_id

                if exit_code > 128 then
                    local signum = exit_code - 128
                    local signame = require("ceramicist.signalnames")[signum]
                    if signame then
                        exit_code = signame
                    end
                end

                if chan_id ~= nil then
                    session.add_empty_lines(config.output.padding)

                    session.add_extmark {
                        hl_mode = "combine",
                        line_hl_group = exit_code == 0
                            and context.hl("FooterSuccess")
                            or context.hl("FooterFail"),
                        virt_text_pos = "overlay",
                        virt_text = config.output.footer(exit_code, duration),
                    }

                    vim.api.nvim_chan_send(session.term_channel_id, "\n")
                end

                -- Update the session only if it was not replaced by another one.
                if job_id == session.running_job_id then
                    session.running_job_id = nil

                    -- Wait before stopinsert, so the updates on the terminal
                    -- can keep updating the cursor position.
                    vim.defer_fn(
                        function()
                            if vim.api.nvim_get_current_buf() == session.buffer then
                                vim.cmd.stopinsert()
                            end
                        end,
                        20
                    )
                end

                -- Nvim 0.12 does not remove extmarks when lines are discarded
                -- in the scrollback. Those are accumulated at the first line
                -- of the buffer.
                --
                -- As a workaround, when a job is finished, and the scrollback
                -- is full, extmarks on the first line are removed.
                local buffer = session.buffer
                if vim.api.nvim_buf_is_valid(buffer) then
                    vim.bo[session.buffer].busy = 0

                    local max_lines = vim.fn.winheight(window) + vim.bo[buffer].scrollback

                    if max_lines <= vim.api.nvim_buf_line_count(buffer) then
                        vim.defer_fn(
                            function() vim.api.nvim_buf_clear_namespace(buffer, -1, 0, 1) end,
                            50
                        )
                    end

                    session.redraw_statusline()
                end

                vim.api.nvim_exec_autocmds("User", {
                    pattern = "Ceramicist/JobFinished",
                    data = {
                        cmdline = cmdline,
                        buffer = session.buffer,
                        window = window,
                        context = function() return context end,
                        session = function() return session end,
                    }
                })
            end,

            on_stdout = function(_, data)
                local chan_id = session.term_channel_id

                if chan_id == nil then return end

                for i, line in ipairs(data) do
                    if not win_cleared then
                        -- Check if the line contains a CUP or DECSED sequence,
                        -- and add empty lines before it.
                        --
                        -- This solution is very naïve, and does not cover every
                        -- case, but it works well enough.
                        --
                        -- Limit to chunks of 256 bytes to reduce the performance
                        -- impact when the process is writing a lot of data.
                        if #data <= 256 then
                            local idx = string.find(line, "\x1B%[[0-9;]*[HJ]")
                            if idx ~= nil then
                                win_cleared = true

                                local winh = vim.fn.winheight(window)
                                line = string.sub(line, 1, idx - 1)
                                        .. string.rep("\r\n", winh)
                                        .. string.sub(line, idx)
                            end
                        end
                    end

                    if i > 1 then
                        line = "\n" .. line
                    end

                    vim.api.nvim_chan_send(chan_id, line)
                end
            end,
        }
    )

    session.running_job_id = job_id

    vim.api.nvim_exec_autocmds("User", {
        pattern = "Ceramicist/JobStarted",
        data = {
            cmdline = cmdline,
            buffer = session.buffer,
            window = window,
            context = function() return context end,
            session = function() return session end,
        }
    })

    session.redraw_statusline()
end

return M
