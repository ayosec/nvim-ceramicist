local M = {}

--- @param config ceramicist.Config
--- @return ceramicist.Context
function M.setup(config)
    config = vim.tbl_deep_extend("force",
        require("ceramicist.config").defaults(),
        config
    )

    --- @class ceramicist.Context
    local context = {
        config = config,

        --- @type { [integer]: ceramicist.Session }
        sessions = {},
    }

    if config.user_command and config.user_command ~= "" then
        require("ceramicist.usercmds").create_user_command(context, config.user_command)
    end

    -- Default highlights
    local hl = vim.api.nvim_set_hl
    local np = config.highlight_name_prefix
    hl(0, np .. "Normal", { default = true  })
    hl(0, np .. "Header", { link = "DiagnosticVirtualLinesInfo", default = true  })

    hl(0, np .. "FooterFail", { link = "DiagnosticVirtualLinesError", default = true  })
    hl(0, np .. "FooterSuccess", { link = "DiagnosticVirtualLinesOk", default = true  })

    return context
end

return M
