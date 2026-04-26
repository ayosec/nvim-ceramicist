-- The process running in a session must be stopped when the buffer is deleted.

local ffi = require("ffi")

local asserts = require("tests.asserts")
local ceramicist = require("ceramicist")

-- Use a FIFO to detect when the process dies.

ffi.cdef [[ int mkfifo(const char *pathname, int mode); ]]
local fifo = vim.fn.tempname()
asserts.eq(0, ffi.C.mkfifo(fifo, 384))

local fifo_is_open = false

ceramicist.setup { user_command = { name = "C" } }

local buffer = -1
vim.api.nvim_create_autocmd("User", {
    pattern = "Ceramicist/JobStarted",
    callback = function(args)
        fifo_is_open = true
        buffer = args.data.session().buffer
    end
})

vim.cmd("C sleep 100 > " .. fifo)
asserts.eq(true, vim.wait(500, function() return fifo_is_open end))

vim.system({ "cat", fifo }, {}, function() fifo_is_open = false end)
vim.wait(100)

vim.cmd(buffer .. "bd!")
asserts.eq(true, vim.wait(500, function() return not fifo_is_open end))
