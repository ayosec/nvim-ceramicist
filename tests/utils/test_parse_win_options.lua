local asserts = require("tests.asserts")
local utils = require("ceramicist.utils")

--- @param cmd string
local function mods(cmd)
    local m = vim.api.nvim_parse_cmd(cmd, {}).mods
    return m and utils.parse_win_options(m)
end

asserts.eq({ split = "below" }, mods("new"))

asserts.eq("tab", mods("tab new"))
asserts.eq("tab", mods("vertical tab new"))

asserts.eq({ split = "right", vertical = true }, mods("vertical new"))

asserts.eq({ split = "below" }, mods("botright new"))
asserts.eq({ split = "right", vertical = true }, mods("botright vertical new"))

asserts.eq({ split = "above" }, mods("topleft new"))
asserts.eq({ split = "left", vertical = true }, mods("vertical topleft new"))

asserts.eq({ split = "above" }, mods("topleft new"))
asserts.eq({ split = "left", vertical = true }, mods("vertical aboveleft new"))
