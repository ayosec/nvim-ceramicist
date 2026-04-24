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
        last_command = '',

        -- Channel to the job output to the terminal.
        term_channel_id = 0,

        --- @type integer|nil
        running_job_id = nil,
    }

    --- @param cmdline string
    --- @param replace? boolean
    --- @param win_opts "tab"|vim.api.keyset.win_config
    session.run = function(cmdline, replace, win_opts)
        require("ceramicist.runner").run(session, cmdline, replace, win_opts)
    end


    session.term_channel_id = vim.api.nvim_open_term(buffer, {
        on_input = function (_, _, _, data)
            if session.running_job_id then
                vim.api.nvim_chan_send(session.running_job_id, data)
            end
        end
    })

    SESSIONS[new_id] = session

    -- Delete session when the buffer is deleted.
    vim.api.nvim_create_autocmd("BufDelete", {
        buffer = buffer,
        once = true,
        callback = function()
            SESSIONS[new_id] = nil
            session.term_channel_id = 0

            if session.running_job_id ~= nil then
                vim.fn.jobstop(session.running_job_id)
                session.running_job_id = nil
            end
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
        -- By default use the oldest session.
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
