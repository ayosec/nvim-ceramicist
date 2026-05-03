local sessions = require("ceramicist.sessions")
local utils = require("ceramicist.utils")

local M = {}

--- @param context ceramicist.Context
--- @param spec ceramicist.UserCommandSpec
function M.create_user_command(context, spec)
    --- @param args vim.api.keyset.create_user_command.command_args
    local function cmd_impl(args)
        local session_id = nil
        if args.range == 0 then
            -- If the current buffer is a terminal, check if it is
            -- associated with a valid session.
            local current_buffer = vim.api.nvim_win_get_buf(0)
            if vim.bo[current_buffer].buftype == "terminal" then
                for sid, s in pairs(context.sessions) do
                    if s.buffer == current_buffer then
                        session_id = sid
                        break
                    end
                end
            end
        elseif args.range == 1 then
            session_id = args.line2
        elseif args.range > 1 then
            vim.notify("Cannot use a range to run commands", vim.log.levels.ERROR)
            return
        end

        local session = sessions.get_session(context, session_id)
        local win_opts = utils.parse_win_options(args.smods)

        session.run(args.args, args.bang, win_opts)
    end

    vim.api.nvim_create_user_command(spec.name, cmd_impl, {
        force = true,
        desc = "Run command in a Ceramicist buffer",
        count = true,
        addr = "other",
        bang = true,
        nargs = "*",
        complete = spec.complete,
    })
end

return M
