local sessions = require("ceramicist.sessions")
local utils = require("ceramicist.utils")

local M = {}

--- @param args vim.api.keyset.create_user_command.command_args
local function cmd_impl(args)
    local session_id = nil
    if args.range == 1 then
        session_id = args.line1
    elseif args.range > 1 then
        vim.notify("Cannot use a range to run commands", vim.log.levels.ERROR)
        return
    end

    local session = sessions.get_session(session_id)
    local win_opts = utils.parse_win_options(args.smods)

    session.run(args.args, args.bang, win_opts)
end


--- @param name string
function M.create_user_command(name)
    vim.api.nvim_create_user_command(name, cmd_impl, {
        force = true,
        desc = "Run command in a Ceramicist buffer",
        count = true,
        addr = "other",
        bang = true,
        nargs = "+",
        complete = "shellcmdline"
    })
end

return M
