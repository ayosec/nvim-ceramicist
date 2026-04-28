local asserts = require("tests.asserts")
local sessions = require("tests.sessions")
local ceramicist = require("ceramicist")

local context = ceramicist.setup {
    user_command = { name = "C" },
    output = {
        footer = function(exit, duration)
            assert(duration > 0)
            return { { tostring(exit), "" } }
        end,
    }
}

local sessions_count = 0
local jobs_started = 0
local jobs_completed = 0

local last_cmdline = ""
local last_session = nil

vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/SessionCreated",
    callback = function(args)
        assert(vim.api.nvim_buf_is_valid(args.data.buffer))
        sessions_count = sessions_count + 1
    end
})

vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/JobStarted",
    callback = function(args)
        jobs_started = jobs_started + 1
        last_cmdline = args.data.cmdline
    end
})


vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/JobFinished",
    callback = function(args)
        jobs_completed = jobs_completed + 1
        asserts.eq(last_cmdline, args.data.cmdline)
        last_session = args.data.session()
    end
})


-- Add some jobs to the session.
vim.cmd "C echo ABC"
vim.wait(1000, function() return jobs_completed == 1 end)
asserts.eq(last_cmdline, "echo ABC")
asserts.eq(last_session, sessions.current())

-- Repeat, twice
vim.cmd "C"
vim.wait(1000, function() return jobs_completed == 2 end)
asserts.eq(last_cmdline, "echo ABC")
asserts.eq(last_session, sessions.current())

if last_session then last_session.rerun() end
vim.wait(1000, function() return jobs_completed == 3 end)
asserts.eq(last_cmdline, "echo ABC")
asserts.eq(last_session, sessions.current())

-- Another job
vim.cmd "C seq 3"
vim.wait(1000, function() return jobs_completed == 4 end)
asserts.eq(last_cmdline, "seq 3")
asserts.eq(last_session, sessions.current())

--- Failed jobs
vim.cmd "C false"
vim.wait(1000, function() return jobs_completed == 5 end)
asserts.eq(last_cmdline, "false")
asserts.eq(last_session, sessions.current())

vim.cmd "C kill -9 $$"
vim.wait(1000, function() return jobs_completed == 6 end)
asserts.eq(last_cmdline, "kill -9 $$")
asserts.eq(last_session, sessions.current())

asserts.eq(jobs_started, jobs_completed)

-- Verify the output.
local output = sessions.output(sessions.current())

asserts.eq(
    { "ABC", "ABC", "ABC", "1", "2", "3" },
    vim.iter(output.lines):filter(function(l) return l ~= "" end):totable()
)

asserts.eq(
    { "echo ABC", "echo ABC", "echo ABC", "seq 3", "false", "kill -9 $$" },
    vim.iter(output.extmarks)
        :filter(function(e) return e[4].line_hl_group == "CeramicistHeader" end)
        :map(function(e) return e[4].virt_text[1][1] end)
        :totable()
)

asserts.eq(
    { "0", "0", "0", "0" },
    vim.iter(output.extmarks)
        :filter(function(e) return e[4].line_hl_group == "CeramicistFooterSuccess" end)
        :map(function(e) return e[4].virt_text[1][1] end)
        :totable()
)

asserts.eq(
    { "1", "SIGKILL" },
    vim.iter(output.extmarks)
        :filter(function(e) return e[4].line_hl_group == "CeramicistFooterFail" end)
        :map(function(e) return e[4].virt_text[1][1] end)
        :totable()
)

-- Verify that `vim.b` returns the same reference.
assert(vim.b.ceramicist_session() == context.sessions[1])

asserts.eq(sessions_count, 1)
