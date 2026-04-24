local assert = require("tests.asserts")
local utils = require("ceramicist.utils")

--- @param cmd string
local function mods(cmd)
    local m = vim.api.nvim_parse_cmd(cmd, {}).mods
    return m and utils.parse_win_options(m)
end

assert.eq({ split = "below" }, mods("new"))

assert.eq("tab", mods("tab new"))
assert.eq("tab", mods("vertical tab new"))

assert.eq({ split = "right", vertical = true }, mods("vertical new"))

assert.eq({ split = "below" }, mods("botright new"))
assert.eq({ split = "right", vertical = true }, mods("botright vertical new"))

assert.eq({ split = "above" }, mods("topleft new"))
assert.eq({ split = "left", vertical = true }, mods("vertical topleft new"))

assert.eq({ split = "above" }, mods("topleft new"))
assert.eq({ split = "left", vertical = true }, mods("vertical aboveleft new"))
