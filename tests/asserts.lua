local debug = require("debug")

local M = {}

local function error(message)
    local info = debug.getinfo(3)
    vim.print(string.format(
        "[%s:%s] %s\n",
        info.short_src,
        info.currentline,
        message
    ))
    vim.cmd "1cq"
end

function M.eq(a, b)
    if not vim.deep_equal(a, b) then
        error(string.format(
            "%s not equal to %s",
            vim.inspect(a),
            vim.inspect(b)
        ))
    end
end

setmetatable(M, {
    __call = function(_, result, message)
        if not result then
            error(message or "assertion failed")
        end
    end,
})

return M
