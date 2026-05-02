local M = {}

--- @alias ceramicist.HighlightGroup
--- | '"FooterFail"'
--- | '"FooterSuccess"'
--- | '"Header"'
--- | '"Normal"'
--- | '"StatusLineRunning"'
--- | '"StatusLineWatch"'


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

    --- @param group ceramicist.HighlightGroup
    --- @return string
    context.hl = function(group)
        return config.highlight_name_prefix .. group
    end

    if config.user_command and config.user_command ~= "" then
        require("ceramicist.usercmds").create_user_command(context, config.user_command)
    end

    require("ceramicist.watchmode").setup()

    -- Default highlights
    local hl = vim.api.nvim_set_hl
    hl(0, context.hl("Normal"), { default = true  })
    hl(0, context.hl("Header"), { link = "DiagnosticVirtualLinesInfo", default = true })

    hl(0, context.hl("FooterSuccess"), { link = "DiagnosticVirtualLinesOk", default = true })
    hl(0, context.hl("FooterFail"), { link = "DiagnosticVirtualLinesError", default = true })

    hl(0, context.hl("StatusLineRunning"), { italic = true, default = true })
    hl(0, context.hl("StatusLineWatch"), { italic = true, default = true })

    return context
end

--- Return all available sessions.
---
--- @return fun(): ceramicist.Session|nil
function M.list_sessions()
    local bufs = vim.api.nvim_list_bufs()
    local iter = nil
    return function()
        while true do
            local ni, buf = next(bufs, iter)
            if ni == nil or buf == nil then return end

            iter = ni
            local get_session = vim.b[buf].ceramicist_session
            if type(get_session) == "function" then
                return get_session()
            end
        end
    end
end

return M
