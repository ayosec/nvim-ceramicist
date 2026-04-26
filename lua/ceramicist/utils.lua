local M = {}

--- @param mods vim.api.keyset.cmd.mods
--- @return "tab"|vim.api.keyset.win_config
--- @private
function M.parse_win_options(mods)
    if mods.tab ~= -1 then
        return "tab"
    end

    local vrt = mods.vertical

    --- @type vim.api.keyset.win_config
    local opts = { split = "below" }

    if vrt then
        opts.vertical = true
    end

    if mods.split == "botright" or mods.split == "belowright" or mods.split == "" then
        opts.split = vrt and "right" or "below"
    elseif mods.split == "aboveleft" or mods.split == "topleft" then
        opts.split = vrt and "left" or "above"
    end

    return opts
end


--- @param cmdline string
function M.escape_control_chars(cmdline)
    local tr = {
        ["\b"] = "\\b",
        ["\n"] = "\\n",
        ["\r"] = "\\r",
        ["\t"] = "\\t",
        ["\x1b"] = "\\e",
    }

    local function map(chr)
        return tr[chr] or string.format("\\x%02x", string.byte(chr))
    end

    return string.gsub(cmdline, "%c", map)
end


return M
