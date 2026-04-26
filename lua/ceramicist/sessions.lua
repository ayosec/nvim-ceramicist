local extmarks = require("ceramicist.extmarks")

local M = {}

--- @return { [integer]: ceramicist.Session }
local SESSIONS = {}

--- @param new_id integer
--- @return ceramicist.Session
local function new_session(new_id)
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.b[buffer].ceramicist_session_id = new_id

    --- @class ceramicist.Session
    local session = {
        id = new_id,
        buffer = buffer,

        --- @type string|nil
        last_command = nil,

        --- Channel to send data to the terminal instance.
        --- @type integer|nil
        term_channel_id = nil,

        --- Job running in the session, created with |jobstart()|.
        --- @type integer|nil
        running_job_id = nil,
    }

    --- @param cmdline string
    --- @param replace? boolean
    --- @param win_opts "tab"|vim.api.keyset.win_config
    session.run = function(cmdline, replace, win_opts)
        require("ceramicist.runner").run(session, cmdline, replace, win_opts)
    end

    session.clear = function()
        -- Sends the equivalent of a `tput clear` to remove the content.
        if session.term_channel_id ~= nil then
            vim.api.nvim_chan_send(session.term_channel_id, "\x1b[H\x1b[2J\x1b[3J")
        end

        vim.api.nvim_buf_clear_namespace(buffer, -1, 0, -1)
    end

    --- @param count integer
    session.add_empty_lines = function(count)
        if session.term_channel_id ~= nil and count > 0 then
            vim.api.nvim_chan_send(
                session.term_channel_id,
                string.rep("\r\n", count)
            )
        end
    end

    session.add_extmark = extmarks.extmark_handler(session)

    SESSIONS[new_id] = session

    local win_resized_events = vim.api.nvim_create_autocmd("WinResized", {
        callback = function()
            local job_id = session.running_job_id
            local windows = vim.v.event.windows

            if not (job_id and windows) then
                return
            end

            for _, winid in pairs(windows) do
                if vim.api.nvim_win_get_buf(winid) == buffer then
                    vim.fn.jobresize(
                        job_id,
                        vim.fn.winwidth(winid),
                        vim.fn.winheight(winid)
                    )

                    return
                end
            end
        end,
    })

    -- Delete session when the buffer is deleted.
    vim.api.nvim_create_autocmd("BufDelete", {
        buffer = buffer,
        once = true,
        callback = function()
            SESSIONS[new_id] = nil
            session.term_channel_id = nil

            if session.running_job_id ~= nil then
                vim.fn.jobstop(session.running_job_id)
                session.running_job_id = nil
            end

            vim.api.nvim_del_autocmd(win_resized_events)
        end,
    })

    return session
end

--- @param session_id integer|nil
--- @return ceramicist.Session
function M.get_session(session_id)
    local session = nil

    if session_id then
        session = SESSIONS[session_id]
    else
        -- By default use the session with the lowest-id.
        for sid, s in pairs(SESSIONS) do
            if session == nil or sid < session.id then
                session = s
            end
        end
    end

    if not session then
        session = new_session(session_id or 1)
    end

    return session
end

return M
