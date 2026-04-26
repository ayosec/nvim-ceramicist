local config = require("ceramicist.config")

local M = {}

--- @param opts ceramicist.Config
function M.setup(opts)
    opts = vim.tbl_deep_extend("force", config.defaults(), opts)
    config.current = opts

    if opts.user_command and opts.user_command ~= "" then
        require("ceramicist.usercmds").create_user_command(opts.user_command)
    end

    -- Default highlights
    local hl = vim.api.nvim_set_hl
    hl(0, "CeramicistHeader", { link = "DiagnosticVirtualLinesInfo", default = true  })

    hl(0, "CeramicistFooterFail", { link = "DiagnosticVirtualLinesError", default = true  })
    hl(0, "CeramicistFooterSuccess", { link = "DiagnosticVirtualLinesOk", default = true  })
end

return M
