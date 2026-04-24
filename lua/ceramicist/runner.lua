local M = {}

--- @param session ceramicist.Session
--- @param cmdline string
--- @param replace? boolean
--- @param win_opts "tab"|vim.api.keyset.win_config
function M.run(session, cmdline, replace, win_opts)
    -- Interrupt the previous job if it is still running.
    if session.running_job_id then
        vim.fn.jobstop(session.running_job_id)
    end

    -- Reuse a window if the buffer is already visible.
    local window = vim.fn.bufwinid(session.buffer)
    if window ~= -1 then
        vim.fn.win_gotoid(window)
    elseif win_opts == "tab" then
        local tab = vim.api.nvim_open_tabpage(session.buffer, true, {})
        window = vim.api.nvim_tabpage_get_win(tab)
    elseif type(win_opts) == "table" then
        window = vim.api.nvim_open_win(session.buffer, true, win_opts)
    else
        assert(false, "Unreachable")
        return
    end

    -- When the command is executed with bang, send a "Reset to Initial State"
    -- to remove the previous content.
    if replace then
        vim.api.nvim_chan_send(session.term_channel_id, "\x1Bc")
    end

    vim.api.nvim_chan_send(session.term_channel_id, "$ " .. cmdline .. "\n")

    assert(session.term_channel_id ~= 0, "Missing terminal channel")

    vim.fn.win_gotoid(window)
    vim.cmd.startinsert()

    vim.api.nvim_buf_set_name(session.buffer, string.format(
        "[ceramicist#%s] %s",
        session.id,
        #cmdline > 16 and string.sub(cmdline, 0, 16) .. "..." or cmdline
    ))

    local job_id = -1

    job_id = vim.fn.jobstart(
        {
            vim.o.shell,
            vim.o.shellcmdflag,
            cmdline,
        },
        {
            pty = true,
            width = vim.fn.winwidth(window),
            height = vim.fn.winheight(window),

            on_exit = function(_, exit_code)
                local chan_id = session.term_channel_id

                if chan_id ~= 0 then
                    vim.api.nvim_chan_send(chan_id, "\n\nEXIT: " .. exit_code .. "\n")
                end

                -- Update the session only if it was not replaced by another one.
                if job_id == session.running_job_id then
                    session.running_job_id = nil

                    if vim.api.nvim_get_current_buf() == session.buffer then
                        vim.cmd.stopinsert()
                    end
                end
            end,

            on_stdout = function(_, data)
                local chan_id = session.term_channel_id

                for i, line in ipairs(data) do
                    if i > 1 then
                        line = "\n" .. line
                    end

                    vim.api.nvim_chan_send(chan_id, line)
                end
            end,
        }
    )

    session.running_job_id = job_id
end

return M
