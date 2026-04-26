local asserts = require("tests.asserts")

local M = {}

--- Wait up to 200ms to get a valid session.
--- @param context ceramicist.Context
function M.current(context)
    assert(
        vim.wait(200, function() return vim.b.ceramicist_session_id ~= nil end) == true,
        "Timeout waiting for session"
    )

    local session = require("ceramicist.sessions").get_session(context, vim.b.ceramicist_session_id)
    assert(vim.fn.bufwinid(session.buffer) ~= -1, "No window")
    return session
end

--- Wait up to second a job is finished and return the contents of the buffer.
---
--- @param session ceramicist.Session
function M.output(session)
    asserts.eq(
        true,
        vim.wait(1000, function()
            return session.last_command ~= nil and session.running_job_id == nil
        end)
    )

    -- Wait some time to run autocommands.
    vim.wait(50)

    return {
        extmarks = vim.api.nvim_buf_get_extmarks(session.buffer, -1, 0, -1, { details = true }),
        lines = vim.api.nvim_buf_get_lines(session.buffer, 0, -1, false),
    }
end

return M
