local debug = require("debug")

local M = {}

--- @param offset_statck integer|nil
--- @param message string
local function error(offset_statck, message)
    local info = debug.getinfo(3 + (offset_statck or 0))
    vim.print(string.format(
        "[%s:%s] %s\n",
        info.short_src,
        info.currentline,
        message
    ))
    vim.cmd "1cq"
end

function M.eq(a, b, offset_statck)
    if not vim.deep_equal(a, b) then
        error(offset_statck, string.format(
            "%s not equal to %s",
            vim.inspect(a),
            vim.inspect(b)
        ))
    end
end

setmetatable(M, {
    __call = function(_, result, message)
        if not result then
            error(0, message or "assertion failed")
        end
    end,
})

return M
