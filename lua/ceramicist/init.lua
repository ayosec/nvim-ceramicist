local M = {}

--- @param opts ceramicist.Config
function M.setup(opts)
    if opts.user_command then
        require("ceramicist.usercmds").create_user_command(opts.user_command)
    end
end

return M
