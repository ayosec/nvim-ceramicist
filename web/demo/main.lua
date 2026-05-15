vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.shell = vim.fn.exepath("bash")

vim.cmd.syntax "on"
vim.cmd.color "default"

vim.lsp._enabled_configs = {}

local ROOT = os.getenv("ROOT")
local NVIM_SIGNAL = os.getenv("NVIM_SIGNAL")

if ROOT == nil or NVIM_SIGNAL == nil then
    vim.cmd "1cq"
    return
end

vim.opt.runtimepath:append(ROOT)

-- Load the configuration from the README
local README = vim.fn.readblob(ROOT .. "/README.md")
local config = string.match(README, [[<!%-%- demo%-config %-%->%s*```lua(.*)```]])

assert(loadstring(config))()

vim.fn.writefile({ "" }, NVIM_SIGNAL)


-- Simulate inputs.

local function sleep(time)
    if time == 0 then return end
    local co = coroutine.running()
    vim.defer_fn(function() coroutine.resume(co) end, time)
    coroutine.yield()
end

local function t(delay, text)
    sleep(delay)

    local keys = vim.keycode(text)
    for idx = 1, #keys do
        vim.api.nvim_feedkeys(string.sub(keys, idx, idx), "m", false)
        sleep(100)
    end
end

local sections = {
    function()
        -- Run a simple job.
        t(2000, ":C ./run-tests")
        t(1000, "<Cr>")
    end,
    function()
        -- Repeat it.
        t(10000, ":C ")
        t(1000, "<Cr>")
    end,
    function()
        sleep(18000)
        local lines = vim.api.nvim_buf_line_count(0)
        local delay = 2000 / lines
        for _ = 1, lines do
            sleep(delay)
            vim.api.nvim_feedkeys("k", "m", false)
        end
    end,
    function()
        -- Watch mode.
        t(25000, ":CeramicistToggleWatch")
        t(1000, "<Cr>")
        sleep(500)
        vim.api.nvim_input("<C-w><C-w>")
        t(300, ":e run-tests")
        t(1000, "<Cr>")
        sleep(700); vim.api.nvim_input("22G")
        sleep(700); vim.api.nvim_input("f1")
        sleep(700); vim.api.nvim_input("r0")
        t(500, ":wa")
        t(1000, "<Cr>")
    end,
    function()
        -- Show signals.
        t(40000, ":C ")
        t(700, "<Cr>")
        t(1000, "<C-C>")
    end,
    function()
        -- Different sessions
        t(50000, ":vert 2C wc -l run-tests")
        t(1000, "<Cr>")
    end,
}

for _, section in ipairs(sections) do
    coroutine.resume(coroutine.create(section))
end
