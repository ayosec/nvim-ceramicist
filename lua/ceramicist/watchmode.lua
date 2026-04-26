local M = {}

local function toggle_watch()
    local get_session = vim.b.ceramicist_session
    if type(get_session) ~= "function" then
        vim.notify("Current buffer is not a Ceramicist session.", vim.log.levels.ERROR)
        return
    end

    --- @type ceramicist.Session
    local session = get_session()

    -- Disable watch mode.
    if session.watch_mode_autocmd ~= nil then
        vim.api.nvim_del_autocmd(session.watch_mode_autocmd)
        session.watch_mode_autocmd = nil
        session.redraw_statusline()
        return
    end


    -- Enable it.

    --- @type uv.uv_timer_t|nil
    local timer = nil

    session.watch_mode_autocmd = vim.api.nvim_create_autocmd("BufWritePost", {
        callback = function()
            if not vim.api.nvim_buf_is_valid(session.buffer) then
                -- Session was deleted.
                vim.api.nvim_del_autocmd(session.watch_mode_autocmd)
                session.watch_mode_autocmd = nil
                return
            end

            if timer ~= nil then
                timer:stop()
                timer:close()
            end

            timer = vim.defer_fn(function()
                timer = nil
                session.rerun()
            end, 100)
        end
    })

    session.redraw_statusline()
end

function M.setup()
    vim.api.nvim_create_user_command("CeramicistToggleWatch", toggle_watch, {
        force = true,
        desc = "Toggle watch mode in the current Ceramicist buffer",
        nargs = 0,
    })
end

return M
