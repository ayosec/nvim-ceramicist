local extmarks = require("ceramicist.extmarks")

local M = {}

--- @class ceramicist.LastJob
--- @field cmdline string
--- @field cwd string

--- @param context ceramicist.Context
--- @param new_id integer
--- @return ceramicist.Session
local function new_session(context, new_id)
    local buffer = vim.api.nvim_create_buf(true, false)

    --- @class ceramicist.Session
    local session = {
        id = new_id,
        buffer = buffer,

        --- @type integer|nil
        watch_mode_autocmd = nil,

        --- @type ceramicist.LastJob|nil
        last_job = nil,

        --- Channel to send data to the terminal instance.
        --- @type integer|nil
        term_channel_id = nil,

        --- Job running in the session, created with |jobstart()|.
        --- @type integer|nil
        running_job_id = nil,
    }

    vim.b[buffer].ceramicist_session = function() return session end

    vim.b[buffer].ceramicist_statusline = function()
        local action = ""
        local cmdline = ""

        if session.is_running() then
            action = "%#" .. context.hl("StatusLineJobStatus") .. "#RUNNING%##   "
        elseif session.is_watching() then
            action = "%#" .. context.hl("WatchMode") .. "#WATCH%##   "
        end

        if session.last_job ~= nil then
            cmdline = string.gsub(session.last_job.cmdline, "%%", "%%%%")
        end

        return string.format("[#%s]   %s%s", new_id, action, cmdline)
    end

    --- @param cmdline string
    --- @param replace boolean
    --- @param win_opts "tab"|vim.api.keyset.win_config
    session.run = function(cmdline, replace, win_opts)
        local run = require("ceramicist.runner").run

        local cwd = nil
        if string.find(cmdline, "%S") == nil then
            if session.last_job == nil then
                vim.notify(
                    "No command to rerun. Type a new command as the arguments for :"
                        .. context.config.user_command.name,
                    vim.log.levels.ERROR
                )
                return
            end

            cwd = session.last_job.cwd
            cmdline = session.last_job.cmdline
        end

        run(context, cwd, session, cmdline, replace, true, win_opts)
    end

    --- Rerun the last job in the session if the window is visible.
    ---
    --- Focus is kept in the window before the rerun.
    session.rerun = function()
        local lj = session.last_job
        if lj == nil then return end

        local run = require("ceramicist.runner").run
        run(context, lj.cwd, session, lj.cmdline, false, false, {})
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

    session.redraw_statusline = function()
        vim.api.nvim__redraw {
            buf = buffer,
            statusline = true,
        }
    end

    session.is_running = function() return session.running_job_id ~= nil end

    session.is_watching = function() return session.watch_mode_autocmd ~= nil end

    session.add_extmark = extmarks.extmark_handler(session)

    context.sessions[new_id] = session

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
            context.sessions[new_id] = nil
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

--- @param context ceramicist.Context
--- @param session_id integer|nil
--- @return ceramicist.Session
function M.get_session(context, session_id)
    local session = nil

    if session_id then
        session = context.sessions[session_id]
    else
        -- By default use the session with the lowest-id.
        for sid, s in pairs(context.sessions) do
            if session == nil or sid < session.id then
                session = s
            end
        end
    end

    if not session then
        session = new_session(context, session_id or 1)
    end

    return session
end

return M
