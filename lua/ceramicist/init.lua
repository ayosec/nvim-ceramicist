local M = {}

--- @param opts ceramicist.Config
function M.setup(opts)
    if opts.user_command then
        require("ceramicist.usercmds").create_user_command(opts.user_command)
    end

    -- Default highlights
    local hl = vim.api.nvim_set_hl
    hl(0, "CeramicistHeaderLine", { fg = "White", bg = "DarkBlue", default = true  })

    hl(0, "CeramicistFooterFail", { fg = "White", bg = "Maroon", default = true  })
    hl(0, "CeramicistFooterSuccess", { fg = "White", bg = "DarkGreen", default = true  })
end

return M
