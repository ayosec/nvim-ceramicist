-- Use session in current buffer when no number is given.

local asserts = require("tests.asserts")
local ceramicist = require("ceramicist")

local last_session = nil
vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/JobStarted",
    callback = function(args)
        last_session = args.data.session()
    end
})

local context = ceramicist.setup { user_command = { name = "C" } }

--- @param command string
--- @param session_id integer
local function run(command, session_id)
    last_session = nil
    vim.cmd(command)
    vim.wait(1000, function() return last_session ~= nil end)
    assert(last_session ~= nil)
    asserts.eq(last_session.id, session_id, 1)
    vim.wait(1000, function() return last_session.running_job_id == nil end)
end

run("C :", 1)
run("2C :", 2)
run("C :", 2)

vim.cmd.new()
run("C :", 1)

vim.cmd.bdelete { range = { context.sessions[1].buffer }, bang = true }
run("C :", 2)

run("3C :", 3)
vim.cmd.b { range = { context.sessions[2].buffer } }
run("C :", 2)
