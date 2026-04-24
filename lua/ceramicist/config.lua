local M = {}

function M.defaults()
    --- @class ceramicist.Config
    local config = {
        --- Name of the user command to open execute a job.
        ---
        --- If `nil`, no command will be created.
        ---
        ---@type string|nil
        user_command = "Ceramicist",
    }

    return config
end

return M
