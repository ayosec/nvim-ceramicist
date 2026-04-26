local utils = require("ceramicist.utils")

local M = {}


--- @param session ceramicist.Session
--- @param cmdline string
local function emit_header(session, cmdline)
    if session.term_channel_id == nil then return end

    session.add_extmark {
        hl_mode = "combine",
        line_hl_group = "CeramicistHeaderLine",
        virt_text_pos = "overlay",
        virt_text = { { utils.escape_control_chars(cmdline), "" } }
    }

    -- Send OSC 133 sequence to allow using [[ and ]] mappings.
    vim.api.nvim_chan_send(
        session.term_channel_id,
        "\x1B]133;A\x07\n"
    )
end

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
                end
            end
        })
    end

    assert(session.term_channel_id ~= 0, "Missing terminal channel")

    emit_header(session, cmdline)

    vim.fn.win_gotoid(window)
    vim.cmd.startinsert()

    vim.api.nvim_buf_set_name(session.buffer, string.format(
        "[ceramicist#%s] %s",
        session.id,
        #cmdline > 16 and string.sub(cmdline, 0, 16) .. "..." or cmdline
    ))

    local job_id = -1

    session.last_command = cmdline
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

                if chan_id ~= nil then
                    session.add_extmark {
                        hl_mode = "combine",
                        line_hl_group = exit_code == 0
                            and "CeramicistFooterSuccess"
                            or "CeramicistFooterFail",
                        virt_text_pos = "overlay",
                        virt_text = { { "Exit code: " .. exit_code, "" } }
                    }

                    vim.api.nvim_chan_send(session.term_channel_id, "\n")
                end

                -- Update the session only if it was not replaced by another one.
                if job_id == session.running_job_id then
                    session.running_job_id = nil

                    if vim.api.nvim_get_current_buf() == session.buffer then
                        vim.cmd.stopinsert()
                    end
                end

                -- Nvim 0.12 does not remove extmarks when lines are discarded
                -- in the scrollback. Those are accumulated at the first line
                -- of the buffer.
                --
                -- As a workaround, when a job is finished, and the scrollback
                -- is full, extmarks on the first line are removed.
                local buffer = session.buffer
                local max_lines = vim.fn.winheight(window) + vim.bo[buffer].scrollback

                if max_lines <= vim.api.nvim_buf_line_count(buffer) then
                    vim.defer_fn(
                        function() vim.api.nvim_buf_clear_namespace(buffer, -1, 0, 1) end,
                        50
                    )
                end
            end,

            on_stdout = function(_, data)
                local chan_id = session.term_channel_id

                if chan_id == nil then return end

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
